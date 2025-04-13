import 'package:filmly/services/user_movie_service.dart';
import 'package:filmly/tmdb_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:card_swiper/card_swiper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' show min, max;

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<String> genres = [];
  String director = 'Cargando director...';
  String errorMessage = '';
  List<Map<String, dynamic>> cast = [];
  final UserMovieService _movieService = UserMovieService();
  bool _isWatched = false;
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _castScrollController = ScrollController();
  final ScrollController _recommendationsScrollController = ScrollController();
  // Mapeo de IDs de géneros a nombres
  final Map<int, String> genreMap = {
    28: 'Acción',
    12: 'Aventura',
    16: 'Animación',
    35: 'Comedia',
    80: 'Crimen',
    99: 'Documental',
    18: 'Drama',
    10751: 'Familiar',
    14: 'Fantasía',
    36: 'Histórico',
    27: 'Terror',
    10402: 'Música',
    9648: 'Misterio',
    10749: 'Romántico',
    878: 'Ciencia ficción',
    10770: 'Película de TV',
    53: 'Suspenso',
    10752: 'Bélica',
    37: 'Western',
  };

  @override
  void initState() {
    super.initState();
    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _loadGenres();
    _loadDirector();
    _loadCast();
    _checkIfWatched();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _castScrollController.dispose();
    _recommendationsScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfWatched() async {
    try {
      final isWatched =
          await _movieService.isWatched(widget.movie['id'].toString());
      if (mounted) {
        setState(() {
          _isWatched = isWatched;
        });
      }
    } catch (e) {
      // Manejar error
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final isFavorite =
          await _movieService.isFavorite(widget.movie['id'].toString());
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Manejar error
    }
  }

  Future<List<Map<String, dynamic>>> _recommendedMovies() async {
    final movieId = widget.movie['id'];
    final apiKey = TMDbService().apiKey; // Tu API key
    final url =
        'https://api.themoviedb.org/3/movie/$movieId/recommendations?api_key=$apiKey&language=en-US&page=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> movies =
            List<Map<String, dynamic>>.from(data['results']);
        return movies;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  _getBannerImage() {
    if (widget.movie['backdrop_path'] != null) {
      return 'https://image.tmdb.org/t/p/original${widget.movie['backdrop_path']}';
    } else {
      return 'assets/placeholder.png';
    }
  }

  Future<void> _loadCast() async {
    final movieId = widget.movie['id'];
    final apiKey = TMDbService().apiKey; // Tu API key
    final url =
        'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&language=en-US&append_to_response=credits';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Obtener el cast (actores y actrices)
        final castList =
            List<Map<String, dynamic>>.from(data['credits']['cast']);
        setState(() {
          cast = castList;
        });
      } else {
        setState(() {
          errorMessage =
              'Error al cargar el cast. Código: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los datos: $e';
      });
    }
  }

  // Método para cargar los géneros desde los IDs de la película
  void _loadGenres() {
    try {
      final genreIds = List<int>.from(widget.movie['genre_ids'] ?? []);
      setState(() {
        genres = genreIds.map((id) => genreMap[id] ?? 'Desconocido').toList();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los géneros: $e';
      });
    }
  }

  // Método para cargar el director de la película
  Future<void> _loadDirector() async {
    final movieId = widget.movie['id'];
    final apiKey =
        TMDbService().apiKey; // Reemplaza con tu clave de API de TMDB
    final url =
        'https://api.themoviedb.org/3/movie/$movieId/credits?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final directorData = data['crew'].firstWhere(
            (crewMember) => crewMember['job'] == 'Director',
            orElse: () => null);

        setState(() {
          director = directorData != null
              ? directorData['name']
              : 'Director no disponible';
        });
      } else {
        setState(() {
          errorMessage =
              'Error al cargar el director. Código: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar el director: $e';
      });
    }
  }

  Future<String> _loadDescripcion() async {
    final movieId = widget.movie['id'];
    final apiKey = TMDbService().apiKey; // Tu API key

    // Intentar cargar la descripción en español
    final urlEs =
        'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&language=es-ES';
    try {
      final responseEs = await http.get(Uri.parse(urlEs));
      if (responseEs.statusCode == 200) {
        final dataEs = json.decode(responseEs.body);
        if (dataEs['overview'] != null && dataEs['overview'].isNotEmpty) {
          return dataEs['overview'];
        }
      }
    } catch (e) {
      // Ignorar el error y continuar con la solicitud en inglés
    }

    // Si no hay descripción en español, intentar en inglés
    final urlEn =
        'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&language=en-US';
    try {
      final responseEn = await http.get(Uri.parse(urlEn));
      if (responseEn.statusCode == 200) {
        final dataEn = json.decode(responseEn.body);
        return dataEn['overview'] ?? 'No hay descripción disponible.';
      } else {
        return 'Error al cargar la descripción. Código: ${responseEn.statusCode}';
      }
    } catch (e) {
      return 'Error al cargar la descripción: $e';
    }
  }

  Future<String> _loadTrailer() async {
    final movieId = widget.movie['id'];
    final apiKey = TMDbService().apiKey; // Tu API key

    // Intentar cargar el tráiler en español
    final urlEs =
        'https://api.themoviedb.org/3/movie/$movieId/videos?api_key=$apiKey&language=es-ES';
    try {
      final responseEs = await http.get(Uri.parse(urlEs));
      if (responseEs.statusCode == 200) {
        final dataEs = json.decode(responseEs.body);
        final trailerEs = dataEs['results'].firstWhere(
          (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
          orElse: () => null,
        );
        if (trailerEs != null) {
          return 'https://www.youtube.com/watch?v=${trailerEs['key']}';
        }
      }
    } catch (e) {
      // Ignorar el error y continuar con la solicitud en inglés
    }

    // Si no hay tráiler en español, intentar en inglés
    final urlEn =
        'https://api.themoviedb.org/3/movie/$movieId/videos?api_key=$apiKey&language=en-US';
    try {
      final responseEn = await http.get(Uri.parse(urlEn));
      if (responseEn.statusCode == 200) {
        final dataEn = json.decode(responseEn.body);
        final trailerEn = dataEn['results'].firstWhere(
          (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
          orElse: () => null,
        );
        return trailerEn != null
            ? 'https://www.youtube.com/watch?v=${trailerEn['key']}'
            : 'Trailer no disponible';
      } else {
        return 'Error al cargar el trailer. Código: ${responseEn.statusCode}';
      }
    } catch (e) {
      return 'Error al cargar el trailer: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = widget.movie['poster_path'] != null
        ? 'https://image.tmdb.org/t/p/w500${widget.movie['poster_path']}'
        : 'assets/placeholder.png';

    final genresText =
        genres.isNotEmpty ? genres.join(', ') : 'Género no disponible';
    final voteAverage =
        widget.movie['vote_average']?.toStringAsFixed(1) ?? 'N/A';
    final releaseDate = _formatReleaseDate(widget.movie['release_date']);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(posterUrl),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de información principal
                  _buildInfoSection(genresText, voteAverage, releaseDate),

                  // Sección de acciones
                  _buildActionButtons(),

                  // Sección de descripción
                  _buildDescriptionSection(),

                  // Sección de reparto
                  _buildImprovedCast(),

                  // Sección de películas recomendadas
                  _buildImprovedRecommendedMovies(),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
    );
  }

  Widget _buildSliverAppBar(String posterUrl) {
    // Get voteAverage directly from the widget data
    final voteAverage =
        widget.movie['vote_average']?.toStringAsFixed(1) ?? 'N/A';

    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            CachedNetworkImage(
              imageUrl: _getBannerImage(),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black,
                child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6347))),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black,
                child:
                    const Center(child: Icon(Icons.error, color: Colors.white)),
              ),
            ),
            // Overlay gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                    const Color(0xFF1A1A1A),
                  ],
                ),
              ),
            ),
            // Poster y título superpuesto en la parte inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Poster con sombra
                    Hero(
                      tag: 'movie-poster-${widget.movie['id']}',
                      child: Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFF6347)),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/placeholder.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Título y valoración
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie['title'] ?? 'Título no disponible',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Contenedor para el rating con estilo de chip
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(
                                          widget.movie['vote_average'])
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getRatingColor(
                                        widget.movie['vote_average']),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: _getRatingColor(
                                          widget.movie['vote_average']),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      voteAverage,
                                      style: TextStyle(
                                        color: _getRatingColor(
                                            widget.movie['vote_average']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          splashColor: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String genresText, String voteAverage, String releaseDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Géneros con estilo de chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres
                .map((genre) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6347).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF6347).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        genre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Información del director y fecha
          Row(
            children: [
              const Icon(
                Icons.movie_creation,
                color: Color(0xFFFF6347),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Director: ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  director,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFFFF6347),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Lanzamiento: ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  releaseDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            label: _isFavorite ? 'Favorita' : 'Añadir a favoritos',
            color: const Color(0xFFFF6347),
            onPressed: () async {
              try {
                final movieId = widget.movie['id'].toString();

                if (_isFavorite) {
                  await _movieService.removeFromFavorites(movieId);
                  if (mounted) {
                    setState(() {
                      _isFavorite = false;
                    });
                    _showSnackBar('Película eliminada de favoritas',
                        isError: false);
                  }
                } else {
                  await _movieService.addToFavorites(movieId);
                  if (mounted) {
                    setState(() {
                      _isFavorite = true;
                    });
                    _showSnackBar('Película añadida a favoritas',
                        isError: false);
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: ${e.toString()}', isError: true);
                }
              }
            },
          ),
          _buildActionButton(
            icon: _isWatched ? Icons.visibility : Icons.visibility_outlined,
            label: _isWatched ? 'Vista' : 'Marcar como vista',
            color: const Color(0xFF3CB371),
            onPressed: () async {
              try {
                final movieId = widget.movie['id'].toString();

                if (_isWatched) {
                  await _movieService.removeFromWatched(movieId);
                  if (mounted) {
                    setState(() {
                      _isWatched = false;
                    });
                    _showSnackBar('Película eliminada de vistas',
                        isError: false);
                  }
                } else {
                  await _movieService.addToWatched(movieId);
                  if (mounted) {
                    setState(() {
                      _isWatched = true;
                    });
                    _showSnackBar('Película marcada como vista',
                        isError: false);
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: ${e.toString()}', isError: true);
                }
              }
            },
          ),
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Ver trailer',
            color: const Color(0xFF64B5F6),
            onPressed: () async {
              try {
                final String trailerUrl = await _loadTrailer();
                final Uri url = Uri.parse(trailerUrl);

                if (!await launchUrl(url)) {
                  throw 'No se pudo abrir $trailerUrl';
                }
              } catch (e) {
                _showSnackBar('No se pudo cargar el trailer', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          label: Text(
            label,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: Color(0xFFFF6347),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sinopsis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFFF6347), thickness: 1, height: 24),
          FutureBuilder<String>(
            future: _loadDescripcion(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFFFF6347)),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Error al cargar la descripción',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final description =
                    snapshot.data ?? 'No hay descripción disponible.';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImprovedCast() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people,
                color: Color(0xFFFF6347),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Reparto principal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFFF6347), thickness: 1, height: 24),
          if (cast.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFFF6347)),
              ),
            )
          else
            SizedBox(
              height: 230, // Aumenté la altura para acomodar los controles
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _castScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: cast.length > 10 ? 10 : cast.length,
                    itemBuilder: (context, index) {
                      final member = cast[index];
                      final profileUrl = member['profile_path'] != null
                          ? 'https://image.tmdb.org/t/p/w200${member['profile_path']}'
                          : 'assets/placeholder.png';

                      // El resto del código del itemBuilder se mantiene igual
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            // Imagen del actor
                            Container(
                              width: 100,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: profileUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFFFF6347)),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.person,
                                        color: Colors.white70),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Nombre y personaje
                            SizedBox(
                              width: 100,
                              child: Column(
                                children: [
                                  Text(
                                    member['name'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    member['character'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Botones de navegación superpuestos
                  if (cast.length > 3) ...[
                    // Botón izquierdo
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_castScrollController.hasClients) {
                                  final currentPosition =
                                      _castScrollController.offset;
                                  final scrollTo =
                                      max(0, currentPosition - 250).toDouble();
                                  _castScrollController.animateTo(
                                    scrollTo,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              splashColor: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF6347).withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botón derecho
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_castScrollController.hasClients) {
                                  final currentPosition =
                                      _castScrollController.offset;
                                  final scrollTo = min(
                                    _castScrollController
                                        .position.maxScrollExtent,
                                    currentPosition + 250,
                                  );
                                  _castScrollController.animateTo(
                                    scrollTo,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              splashColor: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF6347).withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImprovedRecommendedMovies() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.recommend,
                color: Color(0xFFFF6347),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Películas recomendadas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFFF6347), thickness: 1, height: 24),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _recommendedMovies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFFFF6347)),
                  ),
                );
              } else if (snapshot.hasError ||
                  (snapshot.data?.isEmpty ?? true)) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white.withOpacity(0.5),
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.hasError
                            ? 'Error al cargar recomendaciones'
                            : 'No hay películas recomendadas disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                final movies = snapshot.data!;
                return SizedBox(
                  height: 280, // Aumenté la altura para los controles
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _recommendationsScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: movies.length,
                        itemBuilder: (context, index) {
                          final movie = movies[index];
                          final posterUrl = movie['poster_path'] != null
                              ? 'https://image.tmdb.org/t/p/w342${movie['poster_path']}'
                              : 'assets/placeholder.png';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MovieDetailsScreen(movie: movie),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // El resto del código del itemBuilder se mantiene igual
                                  Container(
                                    width: 120,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            imageUrl: posterUrl,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 180,
                                            placeholder: (context, url) =>
                                                Container(
                                              color: Colors.grey[900],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color:
                                                            Color(0xFFFF6347)),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.white70),
                                            ),
                                          ),
                                        ),
                                        // Overlay con rating
                                        if (movie['vote_average'] != null)
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: _getRatingColor(
                                                        movie['vote_average']),
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    movie['vote_average']
                                                        .toStringAsFixed(1),
                                                    style: TextStyle(
                                                      color: _getRatingColor(
                                                          movie[
                                                              'vote_average']),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      movie['title'] ?? 'Sin título',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (movie['release_date'] != null &&
                                      movie['release_date'].isNotEmpty)
                                    Text(
                                      movie['release_date'].split('-')[0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Botones de navegación para películas recomendadas
                      if (snapshot.hasData && snapshot.data!.length > 3) ...[
                        // Botón izquierdo
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (_recommendationsScrollController
                                        .hasClients) {
                                      final currentPosition =
                                          _recommendationsScrollController
                                              .offset;
                                      final scrollTo =
                                          max(0, currentPosition - 250)
                                              .toDouble(); // Convert to double
                                      _recommendationsScrollController
                                          .animateTo(
                                        scrollTo,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  splashColor: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6347)
                                          .withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Botón derecho
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (_recommendationsScrollController
                                        .hasClients) {
                                      final currentPosition =
                                          _recommendationsScrollController
                                              .offset;
                                      final scrollTo = min(
                                        _recommendationsScrollController
                                            .position.maxScrollExtent,
                                        currentPosition + 250,
                                      );
                                      _recommendationsScrollController
                                          .animateTo(
                                        scrollTo,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  splashColor: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6347)
                                          .withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Método para formatear la fecha de lanzamiento
  String _formatReleaseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Fecha no disponible';
    }

    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Método para obtener el color según el rating
  Color _getRatingColor(dynamic rating) {
    double numRating = rating is num ? rating.toDouble() : 0.0;
    if (numRating >= 8) {
      return const Color(0xFF4CAF50); // Verde para ratings altos
    }
    if (numRating >= 6) {
      return const Color(0xFFFFD54F); // Amarillo para ratings medios
    }
    if (numRating >= 4) {
      return const Color(0xFFFF9800); // Naranja para ratings bajos
    }
    return const Color(0xFFF44336); // Rojo para ratings muy bajos
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF3CB371),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class Cast extends StatelessWidget {
  const Cast({
    super.key,
    required this.cast,
  });

  final List<Map<String, dynamic>> cast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Reparto principal',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Divider(color: Color(0xFFFF6347)),
          if (cast.isEmpty)
            const Text(
              'Cargando reparto...',
              style: TextStyle(fontSize: 16, color: Colors.white),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height > 700 ? 350 : 370,
              width: double.infinity,
              child: Swiper(
                itemCount: cast.length,
                itemBuilder: (BuildContext context, int index) {
                  final castMember = cast[index];
                  final castImageUrl = castMember['profile_path'] != null
                      ? 'https://image.tmdb.org/t/p/w500${castMember['profile_path']}'
                      : 'assets/placeholder.png';

                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          castImageUrl,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 240,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/placeholder.png',
                              width: 120,
                              height: 180,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        castMember['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        castMember['character'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
                viewportFraction:
                    MediaQuery.of(context).size.width > 700 ? 0.2 : 0.5,
                scale: 0.4,
                control: const SwiperControl(
                  color: Colors.white,
                ),
              ),
            )
        ],
      ),
    );
  }
}

class RecommendedMovies extends StatelessWidget {
  const RecommendedMovies({
    super.key,
    required this.movies,
  });

  final List<Map<String, dynamic>> movies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Películas Recomendadas',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Divider(color: Color(0xFFFF6347)),
          if (movies.isEmpty)
            const Text(
              'Cargando películas recomendadas...',
              style: TextStyle(fontSize: 16, color: Colors.white),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height > 700 ? 450 : 450,
              width: double.infinity,

              // Utilizamos el 30% del alto de la pantalla
              child: Swiper(
                itemCount: movies.length,
                itemBuilder: (BuildContext context, int index) {
                  final movie = movies[index];
                  final posterUrl = movie['poster_path'] != null
                      ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
                      : 'assets/placeholder.png';

                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/placeholder.png',
                              width: 120,
                              height: 180,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie['release_date'] != null
                            ? 'Lanzamiento: ${movie['release_date']}'
                            : 'Fecha no disponible',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
                viewportFraction:
                    MediaQuery.of(context).size.width > 700 ? 0.25 : 0.6,
                scale: 0.4,
                control: const SwiperControl(
                  color: Colors.white,
                ),
                onTap: (index) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(
                        movie: movies[index],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
