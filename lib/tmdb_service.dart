import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class TMDbService {
  final String apiKey = AppConfig.tmdbApiKey;
  final String baseUrl = AppConfig.tmdbBaseUrl;

  // Mapa de géneros en español a IDs
  final Map<String, int> _genreMap = {
    'Acción': 28,
    'Aventura': 12,
    'Comedia': 35,
    'Drama': 18,
    'Fantasía': 14,
    'Terror': 27,
    'Ciencia ficción': 878,
    'Animación': 16,
    'Documental': 99,
  };

  // Método para obtener películas más recientes (en cartelera)
  Future<List<dynamic>> getNowPlayingMovies({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/now_playing?api_key=$apiKey&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load now playing movies');
    }
  }

  // Método para buscar películas con filtros opcionales
  Future<List<dynamic>> searchMovies({
    String? query,
    String? director,
    String? genre,
    int page = 1, // Añadir parámetro de página
  }) async {
    List<dynamic> movies = [];

    // Si se proporciona un título, buscar películas por título
    if (query != null && query.isNotEmpty) {
      final response = await http.get(
        Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$query&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        movies = data['results'];
      } else {
        throw Exception('Failed to load movies');
      }
    }
    // Si no se proporciona un título ni un director, pero se selecciona un género
    else if (genre != null && genre.isNotEmpty && genre != 'Cualquier género') {
      movies = await _getMoviesByGenre(genre, page);
    }
    // Si no se proporciona un título ni un director, y no se selecciona un género
    else {
      movies = await getNowPlayingMovies(page: page);
    }

    // Filtrar por director (si se proporciona)
    if (director != null && director.isNotEmpty) {
      movies = await _filterByDirector(movies, director);
    }

    return movies;
  }

  // Método para obtener películas por género, ordenadas por fecha de lanzamiento
  Future<List<dynamic>> _getMoviesByGenre(String genre, int page) async {
    // Obtener el ID del género seleccionado
    final genreId = _genreMap[genre];

    if (genreId != null) {
      final response = await http.get(
        Uri.parse('$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId&sort_by=release_date.desc&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'];
      } else {
        throw Exception('Failed to load movies by genre');
      }
    }

    return [];
  }

  // Método para filtrar películas por director
  Future<List<dynamic>> _filterByDirector(List<dynamic> movies, String director) async {
    final List<dynamic> filteredMovies = [];

    for (final movie in movies) {
      final creditsResponse = await http.get(
        Uri.parse('$baseUrl/movie/${movie['id']}/credits?api_key=$apiKey'),
      );

      if (creditsResponse.statusCode == 200) {
        final creditsData = json.decode(creditsResponse.body);
        final crew = creditsData['crew'];

        // Buscar si el director está en el equipo
        final isDirector = crew.any((person) =>
        person['job'] == 'Director' && person['name'].toLowerCase().contains(director.toLowerCase()));

        if (isDirector) {
          filteredMovies.add(movie);
        }
      }
    }

    return filteredMovies;
  }

  // Método para obtener el trailer de la película
  Future<String> getMovieTrailer(int movieId) async {
    final url = '$baseUrl/movie/$movieId/videos?api_key=$apiKey&language=es-ES';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          // Obtener el primer video (generalmente el trailer principal)
          final trailerKey = data['results'][0]['key'];
          return trailerKey;
        } else {
          return ''; // No se encontraron trailers
        }
      } else {
        return ''; // Error al obtener los videos
      }
    } catch (e) {
      return ''; // Error de conexión o cualquier otro error
    }
  }
}
