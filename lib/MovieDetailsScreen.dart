import 'package:filmly/tmdb_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:card_swiper/card_swiper.dart';
import 'package:url_launcher/url_launcher.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  List<String> genres = [];
  String director = 'Cargando director...';
  String errorMessage = '';
  List<Map<String, dynamic>> cast = [];

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
    _loadGenres();
    _loadDirector();
    _loadCast();
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

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6347), Color(0xFFFF6F61)], // Naranja cálido
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.movie['title'] ?? 'Detalles de la película',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors
            .transparent, // Fondo transparente para que se vea el gradiente
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Si hay un error, lo mostramos
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            // Parte superior con el fondo gris
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_getBannerImage()),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  opacity: 0.5,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.5), BlendMode.darken),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Verificamos si el ancho de la pantalla es menor que un valor umbral
                  bool isMobile = constraints.maxWidth < 600;

                  return isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Carátula de la película
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                width: !isMobile ? 200 : double.infinity,
                                // Ancho más grande para la carátula
                                height: MediaQuery.of(context).size.width > 450
                                    ? 290
                                    : 200,
                                // Altura más grande para la carátula
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/placeholder.png',
                                    width: 180,
                                    height: 270,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Información de la película
                            Text(
                              widget.movie['title'] ?? 'Título no disponible',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Géneros: $genresText',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    color: Colors.yellow[700], size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  voteAverage,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Botones para añadir a favoritos y marcar como visto
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Acción para añadir a favoritos
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Película añadida a favoritos')),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.favorite_border,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      label: const Text('Favoritos'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFFF6347),
                                        // Naranja cálido
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Acción para marcar como visto
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Película marcada como vista')),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.check,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      label: const Text('Visto'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green, // Verde
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final String trailerUrl =
                                            await _loadTrailer();
                                        final Uri url = Uri.parse(trailerUrl);

                                        if (!await launchUrl(url)) {}
                                      },
                                      icon: const Icon(
                                        Icons.play_arrow,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      label: const Text('Trailer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue, // Azul
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Director: $director',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Fecha de lanzamiento: ${widget.movie['release_date'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Carátula de la película
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                                width: 200,
                                height: 290,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/placeholder.png',
                                    width: 200,
                                    height: 290,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Información de la película
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.movie['title'] ??
                                        'Título no disponible',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Géneros: $genresText',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.star,
                                          color: Colors.yellow[700], size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        voteAverage,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Botones para añadir a favoritos y marcar como visto
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // Acción para añadir a favoritos
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Película añadida a favoritos')),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.favorite_border,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Favoritos'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xFFFF6347),
                                              // Naranja cálido
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // Acción para marcar como visto
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Película marcada como vista')),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.check,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Visto'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green, // Verde
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final String trailerUrl =
                                                  await _loadTrailer();
                                              final Uri url =
                                                  Uri.parse(trailerUrl);

                                              if (!await launchUrl(url)) {}
                                            },
                                            icon: const Icon(
                                              Icons.play_arrow,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Trailer'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue, // Azul
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Director: $director',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Fecha de lanzamiento: ${widget.movie['release_date'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                },
              ),
            ),

            const SizedBox(height: 24),
            // Parte inferior centrada
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Descripción',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Divider(color: Color(0xFFFF6347)),
                  FutureBuilder<String>(
                    future: _loadDescripcion(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text(
                          'Error al cargar la descripción.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        );
                      } else {
                        return Text(
                          snapshot.data ?? 'No hay descripción disponible.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        );
                      }
                    },
                  ),

                  // Aquí mostramos las tarjetas del reparto
                  Cast(cast: cast),
                  // Aquí mostramos las tarjetas de películas recomendadas
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _recommendedMovies(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text(
                          'Error al cargar las películas recomendadas.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        );
                      } else {
                        return RecommendedMovies(movies: snapshot.data ?? []);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(
          0xFF2C2C2C), // Fondo oscuro para coincidir con el estilo de la primera pantalla
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
              height: MediaQuery.of(context).size.height > 700 ? 400 : 370,
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
