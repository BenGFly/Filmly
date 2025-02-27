import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:filmly/services/user_movie_service.dart';
import 'package:filmly/tmdb_service.dart';
import 'package:filmly/MovieDetailsScreen.dart';

class ViewedMoviesScreen extends StatefulWidget {
  const ViewedMoviesScreen({Key? key}) : super(key: key);

  @override
  _ViewedMoviesScreenState createState() => _ViewedMoviesScreenState();
}

class _ViewedMoviesScreenState extends State<ViewedMoviesScreen> {
  final UserMovieService _userMovieService = UserMovieService();
  final TMDbService _tmdbService = TMDbService();
  List<Map<String, dynamic>> _viewedMovies = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadViewedMovies();
  }

  Future<void> _loadViewedMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener los IDs de películas vistas
      final viewedIds = await _userMovieService.getWatched();

      // Cargar los detalles de cada película vista
      List<Map<String, dynamic>> movies = [];

      for (var item in viewedIds) {
        final movieId = item['movie_id'];
        try {
          final movieDetails = await _tmdbService.getMovieDetails(int.parse(movieId));
          movies.add(movieDetails);
        } catch (e) {
          print('Error al cargar detalles de película $movieId: $e');
        }
      }

      setState(() {
        _viewedMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar películas vistas: $e';
        _isLoading = false;
      });
      print('Error: $_errorMessage');
    }
  }

  Future<void> _removeFromViewed(String movieId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _userMovieService.removeFromWatched(movieId);

      // Actualizar la lista después de eliminar
      setState(() {
        _viewedMovies.removeWhere((movie) => movie['id'].toString() == movieId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Película eliminada de vistas'),
          backgroundColor: Color(0xFF3CB371),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar de vistas: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

// ...existing code...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Eliminar la flecha de atrás
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3CB371).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3CB371), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility,
                color: Color(0xFF3CB371),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Películas Vistas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_viewedMovies.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3CB371),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_viewedMovies.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadViewedMovies,
            tooltip: 'Actualizar lista',
          ),
          const SizedBox(width: 8), // Añadir un pequeño margen a la derecha
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Color(0xFF2C2C2C)],
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

// ...existing code...
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3CB371),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadViewedMovies,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3CB371),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_viewedMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 70,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'No has marcado películas como vistas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Marca tus películas como vistas para llevar un registro',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _viewedMovies.length,
      itemBuilder: (context, index) {
        final movie = _viewedMovies[index];
        return _buildMovieCard(movie);
      },
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final posterUrl = movie['poster_path'] != null
        ? 'https://image.tmdb.org/t/p/w200${movie['poster_path']}'
        : 'assets/placeholder.png';
    final voteAverage = (movie['vote_average'] ?? 0).toStringAsFixed(1);
    final releaseDate = _formatReleaseDate(movie['release_date']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailsScreen(movie: movie),
            ),
          ).then((_) => _loadViewedMovies());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster con sombra y borde
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    posterUrl,
                    width: 90,
                    height: 135,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 90,
                        height: 135,
                        color: Colors.grey[700],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información de la película
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['title'] ?? 'Sin título',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating con estilo de chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getRatingColor(movie['vote_average']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRatingColor(movie['vote_average']),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: _getRatingColor(movie['vote_average']),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                voteAverage,
                                style: TextStyle(
                                  color: _getRatingColor(movie['vote_average']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Fecha
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                releaseDate,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Géneros
                    if (movie['genres'] != null && movie['genres'].isNotEmpty)
                      SizedBox(
                        height: 24,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movie['genres'].length,
                          itemBuilder: (context, index) {
                            final genre = movie['genres'][index];
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3CB371).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF3CB371),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                genre['name'],
                                style: const TextStyle(
                                  color: Color(0xFF3CB371),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    // Resumen
                    if (movie['overview'] != null && movie['overview'].isNotEmpty)
                      Text(
                        movie['overview'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    const SizedBox(height: 10),
                    // Botón para eliminar de vistas
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _showRemoveDialog(movie),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Eliminar de vistas',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(Map<String, dynamic> movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '¿Quitar de películas vistas?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro que deseas quitar "${movie['title']}" de tu lista de películas vistas?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF3CB371))),
          ),
          ElevatedButton(
            onPressed: () {
              _removeFromViewed(movie['id'].toString());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatReleaseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(dateStr);
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getRatingColor(dynamic rating) {
    double numRating = rating is num ? rating.toDouble() : 0.0;
    if (numRating >= 8) return Colors.green;
    if (numRating >= 6) return Colors.amber;
    if (numRating >= 4) return Colors.orange;
    return Colors.red;
  }
}