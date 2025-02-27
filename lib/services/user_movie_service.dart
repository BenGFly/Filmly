import 'package:supabase_flutter/supabase_flutter.dart';

class UserMovieService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // MÉTODOS DE USUARIO

  // Método para registrar un nuevo usuario
  Future<void> registerUser(String email, String password, String name) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email y contraseña no pueden estar vacíos');
    }

    try {
      // Registrar usuario en auth
      final authResponse = await _supabase.auth.signUp(
          email: email,
          password: password
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear el usuario');
      }

      // Crear perfil del usuario en la tabla profiles
      await _supabase.from('profiles').insert({
        'id': authResponse.user!.id,
        'name': name,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('Error en el registro: $e');
    }
  }

  // Obtener perfil del usuario actual
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al obtener el perfil: $e');
    }
  }

  // MÉTODOS PARA PELÍCULAS FAVORITAS

  // Método para agregar una película a favoritos
  Future<void> addToFavorites(String movieId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    if (movieId.isEmpty) {
      throw Exception('MovieId no puede estar vacío');
    }

    try {
      await _supabase.from('user_favorites').upsert({
        'user_id': user.id,
        'movie_id': movieId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al agregar a favoritos: $e');
    }
  }

  // Método para eliminar una película de favoritos
  Future<void> removeFromFavorites(String movieId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('movie_id', movieId);
    } catch (e) {
      throw Exception('Error al eliminar de favoritos: $e');
    }
  }

  // Método para obtener las películas favoritas
  Future<List<dynamic>> getFavorites() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      final data = await _supabase
          .from('user_favorites')
          .select('movie_id, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return data;
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  // Verificar si una película está en favoritos
  Future<bool> isFavorite(String movieId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      final data = await _supabase
          .from('user_favorites')
          .select()
          .eq('user_id', user.id)
          .eq('movie_id', movieId);

      return data.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar favorito: $e');
    }
  }

  // MÉTODOS PARA PELÍCULAS VISTAS

  // Método para marcar una película como vista
  Future<void> addToWatched(String movieId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    if (movieId.isEmpty) {
      throw Exception('MovieId no puede estar vacío');
    }

    try {
      await _supabase.from('user_watched').upsert({
        'user_id': user.id,
        'movie_id': movieId,
        'watched_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al marcar como vista: $e');
    }
  }

  // Método para eliminar una película de vistas
  Future<void> removeFromWatched(String movieId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      await _supabase
          .from('user_watched')
          .delete()
          .eq('user_id', user.id)
          .eq('movie_id', movieId);
    } catch (e) {
      throw Exception('Error al eliminar de vistas: $e');
    }
  }

  // Método para obtener las películas vistas
  Future<List<dynamic>> getWatched() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      final data = await _supabase
          .from('user_watched')
          .select('movie_id,watched_at')
          .eq('user_id', user.id)
          .order('watched_at', ascending: false);

      return data;
    } catch (e) {
      throw Exception('Error al obtener vistas: $e');
    }
  }

  // Verificar si una película está marcada como vista
  Future<bool> isWatched(String movieId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      final data = await _supabase
          .from('user_watched')
          .select()
          .eq('user_id', user.id)
          .eq('movie_id', movieId);

      return data.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar si está vista: $e');
    }
  }
}