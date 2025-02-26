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
      throw Exception('Failed to load movies');
    }
  }

  // Método para buscar películas con filtros opcionales
  Future<List<dynamic>> searchMovies({
    String? query,
    String? director,
    String? genre,
    double? rating,
    String? dateFilter,
    int page = 1,
  }) async {
    List<dynamic> movies = [];

    // Si hay una búsqueda por título, obtenemos las películas con ese título
    if (query != null && query.isNotEmpty) {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/search/movie?api_key=$apiKey&query=$query&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        movies = data['results'];
      } else {
        throw Exception('Failed to load movies');
      }
    }
    // Si no hay título, pero hay género, obtenemos películas por género
    else if (genre != null && genre.isNotEmpty && genre != 'Cualquier género') {
      movies = await _getMoviesByGenre(genre, page,rating??0);
    } else if (director != null && director.isNotEmpty) {
      movies = await _SearchByDirector(director);
    }
    // Si no hay título ni género, obtenemos las películas en cartelera
    else {
      movies = await getNowPlayingMovies(page: page);
    }

    if (director != null && director.isNotEmpty) {
      movies = await _filterMoviesByDirector(movies, director);
    }

    // Si también se busca por género, asegurarnos de que las películas sean del género correcto
    if (genre != null && genre.isNotEmpty && genre != 'Cualquier género') {
      movies = _filterMoviesByGenre(movies, genre);
    }

    // Si se busca por rating, filtrar las películas por rating
    if (rating != null) {
      movies = await _filterByRating(movies, rating);
    }

    // Si se busca por fecha, filtrar las películas por fecha

    if (dateFilter != null && dateFilter.isNotEmpty) {
      movies = await _filterByDate(movies, dateFilter);
    }

    return movies;
  }

  Future<List<dynamic>> _filterByRating(List<dynamic> movies,
      double rating) async {
    return movies.where((movie) {
      final double? movieRating = movie['vote_average'];
      return movieRating != null && movieRating >= rating;
    }).toList();
  }

  Future<List<dynamic>> _filterByDate(List<dynamic> movies,
      String dateFilter) async {
    if (dateFilter == 'Estrenadas recientemente') {
      return movies.where((movie) {
        final String? releaseDate = movie['release_date'];
        return releaseDate != null &&
            DateTime.parse(releaseDate).isAfter(
                DateTime.now().subtract(const Duration(days: 30)));
      }).toList();
    } else if (dateFilter == 'Próximas a estrenarse') {
      return movies.where((movie) {
        final String? releaseDate = movie['release_date'];
        return releaseDate != null &&
            DateTime.parse(releaseDate).isAfter(DateTime.now());
      }).toList();
    } else {
      return movies;
    }
  }

Future<List<dynamic>> _filterMoviesByDirector(List<dynamic> movies,
    String director) async {
  final List<dynamic> filteredMovies = [];

  // Buscar el ID del director
  final directorResponse = await http.get(
    Uri.parse('$baseUrl/search/person?api_key=$apiKey&query=$director'),
  );

  if (directorResponse.statusCode == 200) {
    final directorData = json.decode(directorResponse.body);
    if (directorData['results'] != null &&
        directorData['results'].isNotEmpty) {
      final directorId = directorData['results'][0]['id'];

      // Filtrar películas dirigidas por el director
      for (final movie in movies) {
        final movieId = movie['id'];

        // Obtener créditos de la película
        final creditsResponse = await http.get(
          Uri.parse('$baseUrl/movie/$movieId/credits?api_key=$apiKey'),
        );

        if (creditsResponse.statusCode == 200) {
          final creditsData = json.decode(creditsResponse.body);
          final crew = creditsData['crew'];

          // Verificar si el director dirigió la película
          final isDirectedBy = crew.any(
                (person) =>
            person['id'] == directorId && person['job'] == 'Director',
          );

          if (isDirectedBy) {
            filteredMovies.add(movie);
          }
        }
      }
    }
  }

  return filteredMovies;
}

List<dynamic> _filterMoviesByGenre(List<dynamic> movies, String genre) {
  final genreId = _genreMap[genre];

  if (genreId == null) return movies;

  return movies.where((movie) {
    final List<dynamic>? genres = movie['genre_ids'];
    return genres != null && genres.contains(genreId);
  }).toList();
}

Future<List<dynamic>> _SearchByDirector(String director) async {
  final response = await http.get(
    Uri.parse('$baseUrl/search/person?api_key=$apiKey&query=$director'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final directorId = data['results'][0]['id'];

    final responseMovies = await http.get(
      Uri.parse(
          '$baseUrl/discover/movie?api_key=$apiKey&with_crew=$directorId'),
    );

    if (responseMovies.statusCode == 200) {
      final dataMovies = json.decode(responseMovies.body);
      return dataMovies['results'];
    } else {
      throw Exception('Failed to load movies by director');
    }
  } else {
    throw Exception('Failed to load director');
  }
}

// Método para obtener películas por género,
// Método para obtener películas por género y filtrar por rating mínimo
  Future<List<dynamic>> _getMoviesByGenre(String genre, int page, double rating) async {
    // Obtener el ID del género seleccionado
    final genreId = _genreMap[genre];
    if (genreId == null) return [];

    // Construir la URL con el filtro de género y rating
    final url = Uri.parse(
      '$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId&vote_average.gte=$rating&page=$page',
    );

    // Realizar la solicitud a la API
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results']; // Devolver la lista de películas filtradas
    } else {
      throw Exception('Failed to load movies by genre');
    }
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
}}
