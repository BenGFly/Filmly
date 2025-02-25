import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Cargar variables de entorno
  static final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  static final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  static final String tmdbApiKey = dotenv.env['TMDB_API_KEY']!;
  static final String tmdbBaseUrl = dotenv.env['TMDB_BASE_URL']!;

  // Endpoints de TMDb
  static String tmdbMovieDetailsEndpoint(int movieId) => "$tmdbBaseUrl/movie/$movieId?api_key=$tmdbApiKey";
  static String tmdbSearchEndpoint(String query) => "$tmdbBaseUrl/search/movie?api_key=$tmdbApiKey&query=$query";
  static String tmdbRecommendationsEndpoint(int movieId) => "$tmdbBaseUrl/movie/$movieId/recommendations?api_key=$tmdbApiKey";
}