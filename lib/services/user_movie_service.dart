import 'package:supabase_flutter/supabase_flutter.dart';

class UserMovieService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para agregar una película a favoritos
  Future<void> addMovieToFavorites(String userId, String movieId) async {
    if (userId.isEmpty || movieId.isEmpty) {
      throw Exception('UserId y MovieId no pueden estar vacíos');
    }

    final response = await _supabase.from('user_movies').insert({
      'user_id': userId,
      'movie_id': movieId,
      'status': 'favorite',
    }).execute();

    if (!(response.status == 200 || response.status == 201)) {
      throw Exception('Error al agregar la película a favoritos: ${response.status}');
    }
  }

  // Método para obtener las películas favoritas de un usuario
  Future<List<dynamic>> getUserFavorites(String userId) async {
    final response = await _supabase
        .from('user_movies')
        .select('movie_id')
        .eq('user_id', userId)
        .eq('status', 'favorite')
        .execute();

    if (response.status != 200) {
      throw Exception(
          'Error al obtener las películas favoritas: ${response.status}');
    }

    return response.data as List<dynamic>;
  }

  // Método para marcar una película como vista
  Future<void> addMovieToWatched(String userId, String movieId) async {
    final response = await _supabase.from('user_movies').insert({
      'user_id': userId,
      'movie_id': movieId,
      'status': 'watched',
    }).execute();

    if (!(response.status == 200 || response.status == 201)) {
      throw Exception(
          'Error al marcar la película como vista: ${response.status}');
    }
  }

  // Método para obtener las películas vistas de un usuario
  Future<List<dynamic>> getUserWatched(String userId) async {
    final response = await _supabase
        .from('user_movies')
        .select('movie_id')
        .eq('user_id', userId)
        .eq('status', 'watched')
        .execute();

    if (response.status != 200) {
      throw Exception(
          'Error al obtener las películas vistas: ${response.status}');
    }

    return response.data as List<dynamic>;
  }
}
