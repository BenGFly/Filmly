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

    // Si hay director, empezar siempre por el director ya que es el filtro más restrictivo
    if (director != null && director.isNotEmpty) {
      movies = await _getMoviesByDirector(director, page);
    }
    // Si no hay director pero hay título, buscar por título
    else if (query != null && query.isNotEmpty) {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/search/movie?api_key=$apiKey&query=$query&page=$page&language=es-ES'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        movies = data['results'];
      } else {
        throw Exception('Failed to load movies by title');
      }
    }
    // Si no hay título ni director, pero hay género, buscar por género
    else if (genre != null && genre.isNotEmpty && genre != 'Cualquier género') {
      movies = await _getMoviesByGenre(genre, page, rating ?? 0);
    }
    // Si sólo hay rating, buscar por rating
    else if (rating != null) {
      movies = await _getMoviesByRating(rating, page);
    }
    // Si no hay ningún filtro específico, obtener las películas en cartelera
    else {
      movies = await getNowPlayingMovies(page: page);
    }

    // Aplicar filtros adicionales a los resultados iniciales

    // Si hay título y no se usó como filtro inicial, filtrar por título
    if (query != null &&
        query.isNotEmpty &&
        director != null &&
        director.isNotEmpty) {
      movies = _filterMoviesByTitle(movies, query);
    }

    // Si hay género y no se usó como filtro inicial, filtrar por género
    if (genre != null &&
        genre.isNotEmpty &&
        genre != 'Cualquier género' &&
        (director != null || query != null)) {
      movies = _filterMoviesByGenre(movies, genre);
    }

    // Si hay rating y no se usó como filtro inicial, filtrar por rating
    if (rating != null &&
        (director != null ||
            query != null ||
            (genre != null && genre != 'Cualquier género'))) {
      movies = _filterByRating(movies, rating);
    }

    // Siempre aplicar filtro por fecha si está especificado
    if (dateFilter != null && dateFilter != 'Siempre') {
      movies = _filterByDate(movies, dateFilter);
    }

    return movies;
  }

  Future<List<dynamic>> _getMoviesByDirector(String director, int page) async {
    // Buscar el ID del director
    final directorResponse = await http.get(
      Uri.parse(
          '$baseUrl/search/person?api_key=$apiKey&query=$director&language=es-ES'),
    );

    if (directorResponse.statusCode == 200) {
      final directorData = json.decode(directorResponse.body);

      if (directorData['results'] != null &&
          directorData['results'].isNotEmpty) {
        final directorId = directorData['results'][0]['id'];

        // Usar discover API para encontrar películas donde esta persona fue director
        final moviesResponse = await http.get(
          Uri.parse(
              '$baseUrl/discover/movie?api_key=$apiKey&with_people=$directorId&page=$page&language=es-ES'),
        );

        if (moviesResponse.statusCode == 200) {
          final moviesData = json.decode(moviesResponse.body);
          List<dynamic> directorMovies = moviesData['results'];

          // Verificar roles para asegurar que es director
          List<dynamic> confirmedDirectorMovies = [];
          for (var movie in directorMovies) {
            final creditsResponse = await http.get(
              Uri.parse(
                  '$baseUrl/movie/${movie['id']}/credits?api_key=$apiKey'),
            );

            if (creditsResponse.statusCode == 200) {
              final creditsData = json.decode(creditsResponse.body);
              final crew = creditsData['crew'];

              bool isDirector = crew.any((member) =>
                  member['id'] == directorId && member['job'] == 'Director');

              if (isDirector) {
                confirmedDirectorMovies.add(movie);
              }
            }
          }

          return confirmedDirectorMovies;
        }
      }
    }

    return []; // Si no se encuentra el director o hay algún error
  }

  List<dynamic> _filterMoviesByTitle(List<dynamic> movies, String query) {
    final String lowercaseQuery = query.toLowerCase();

    return movies.where((movie) {
      final String title = (movie['title'] ?? '').toLowerCase();
      final String overview = (movie['overview'] ?? '').toLowerCase();

      return title.contains(lowercaseQuery) ||
          overview.contains(lowercaseQuery);
    }).toList();
  }

  List<dynamic> _filterByDate(List<dynamic> movies, String dateFilter) {
    final now = DateTime.now();

    switch (dateFilter) {
      case 'Hace 1 mes':
        final oneMonthAgo = now.subtract(const Duration(days: 30));
        return movies.where((movie) {
          final String? releaseDate = movie['release_date'];
          if (releaseDate == null || releaseDate.isEmpty) return false;

          try {
            final DateTime movieDate = DateTime.parse(releaseDate);
            return movieDate.isAfter(oneMonthAgo);
          } catch (e) {
            return false;
          }
        }).toList();

      case 'Hace 1 año':
        final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
        return movies.where((movie) {
          final String? releaseDate = movie['release_date'];
          if (releaseDate == null || releaseDate.isEmpty) return false;

          try {
            final DateTime movieDate = DateTime.parse(releaseDate);
            return movieDate.isAfter(oneYearAgo);
          } catch (e) {
            return false;
          }
        }).toList();

      default: // 'Siempre' o cualquier otro valor
        return movies;
    }
  }

  List<dynamic> _filterByRating(List<dynamic> movies, double rating) {
    return movies.where((movie) {
      final dynamic voteAverage = movie['vote_average'];
      if (voteAverage == null) return false;

      double? movieRating;
      if (voteAverage is int) {
        movieRating = voteAverage.toDouble();
      } else if (voteAverage is double) {
        movieRating = voteAverage;
      } else {
        try {
          movieRating = double.parse(voteAverage.toString());
        } catch (e) {
          return false;
        }
      }

      return movieRating >= rating;
    }).toList();
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/movie/$movieId?api_key=$apiKey&language=es-ES&append_to_response=credits'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Error al cargar detalles de la película: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> _filterMoviesByDirector(
      List<dynamic> movies, String director) async {
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

  Future<List<dynamic>> _getMoviesByRating(rating, page) async {
    final url = Uri.parse(
      '$baseUrl/discover/movie?api_key=$apiKey&vote_average.gte=$rating&page=$page',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load movies by rating');
    }
  }

// Método para obtener películas por género y filtrar por rating mínimo
  Future<List<dynamic>> _getMoviesByGenre(
      String genre, int page, double rating) async {
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
  }
}
