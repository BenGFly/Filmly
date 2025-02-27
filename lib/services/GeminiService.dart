import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../tmdb_service.dart';

class GeminiService {
  // URL actualizada para la API de Gemini
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  late String apiKey;
  final int maxRetries = 3;
  final TMDbService _tmdbService = TMDbService();

  GeminiService() {
    apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no encontrada en el archivo .env');
    }
  }

  Future<List<Map<String, dynamic>>> getMovieRecommendations(
      String prompt) async {
    // 1. Obtener recomendaciones de títulos de películas desde Gemini
    final movieTitles = await _getMovieTitlesFromGemini(prompt);

    // 2. Buscar detalles de cada película en TMDB
    final List<Map<String, dynamic>> detailedMovies = [];

    for (final title in movieTitles) {
      try {
        // Buscar la película en TMDB por título
        final searchResults = await _tmdbService.searchMovies(query: title);

        if (searchResults.isNotEmpty) {
          // Obtener los detalles completos del primer resultado
          final movieId = searchResults[0]['id'];
          final movieDetails = await _tmdbService.getMovieDetails(movieId);

          // Añadir a la lista de películas detalladas
          detailedMovies.add(movieDetails);
        }
      } catch (e) {
        print('Error buscando película "$title": $e');
        // Continuar con la siguiente película si hay un error
      }
    }

    return detailedMovies;
  }

  Future<List<String>> _getMovieTitlesFromGemini(String prompt) async {
    int retries = 0;
    late http.Response response;

    while (retries <= maxRetries) {
      try {
        // Estructura específica actualizada para la API de Gemini
        final requestBody = {
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Eres un experto en cine. Por favor, recomiéndame 5 películas que coincidan con esta descripción: '$prompt'. Responde SOLO con un JSON que contiene un array llamado 'titles' con los títulos de las películas, sin ninguna explicación adicional."
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 300,
            "topK": 40,
            "topP": 0.95
          },
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        };

        final queryParams = {
          'key': apiKey,
        };

        // Construir URL con los parámetros de consulta
        final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

        // Realizar solicitud a la API de Gemini
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Verificar que la respuesta tenga la estructura esperada
          if (!data.containsKey('candidates') ||
              data['candidates'].isEmpty ||
              !data['candidates'][0].containsKey('content') ||
              !data['candidates'][0]['content'].containsKey('parts') ||
              data['candidates'][0]['content']['parts'].isEmpty) {
            throw Exception('Formato de respuesta inesperado de Gemini API');
          }

          // Extraer el contenido de la respuesta (estructura específica de Gemini)
          final content = data['candidates'][0]['content']['parts'][0]['text'];

          try {
            // Procesar la respuesta para extraer los títulos
            final String cleanContent = _cleanJsonString(content);
            final Map<String, dynamic> parsedData = jsonDecode(cleanContent);

            // Extraer el array de títulos
            final List<dynamic> titles = parsedData['titles'] ?? [];

            if (titles.isEmpty) {
              // Si no hay títulos, intentar buscarlo como un array directamente
              if (parsedData is List) {
                // Corregido: Las listas no tienen el método 'values'
                return parsedData.values
                    .map((item) => item.toString())
                    .toList();
              } else if (parsedData is Map) {
                // Convert Map values to a list of strings
                return parsedData.values
                    .map((item) => item.toString())
                    .toList();
              }
              throw Exception('No se encontraron títulos en la respuesta');
            }

            // Convertir a lista de strings
            return titles.map((title) => title.toString()).toList();
          } catch (e) {
            print('Error al procesar la respuesta JSON: $e');
            // Si no se pudo procesar como JSON, intentar extraer títulos del texto plano
            return _extractTitlesFromText(content);
          }
        } else if (response.statusCode == 429) {
          // Rate limit exceeded, vamos a esperar e intentarlo de nuevo
          retries++;

          if (retries <= maxRetries) {
            final waitTime = math.pow(2, retries).toInt() * 1000;
            await Future.delayed(Duration(milliseconds: waitTime));
            continue;
          } else {
            throw Exception(
                'Error 429: Límite de cuota excedido. Por favor, inténtalo más tarde.');
          }
        } else {
          print('Error de API: ${response.statusCode} - ${response.body}');
          throw Exception(
              'Error al comunicarse con la API de Gemini: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        if (e is http.ClientException) {
          retries++;
          if (retries <= maxRetries) {
            await Future.delayed(Duration(seconds: retries));
            continue;
          }
        }
        print('Error al obtener recomendaciones: $e');
        // Si después de varios intentos sigue fallando, usar títulos fallback
        return getFallbackMovieTitles(prompt);
      }
    }

    // Si llegamos aquí, usar títulos fallback
    return getFallbackMovieTitles(prompt);
  }

  // El resto de métodos permanece igual

  // Función para extraer títulos de un texto plano cuando falla el parsing JSON
  List<String> _extractTitlesFromText(String text) {
    // Buscar listas numeradas (1. Título)
    final numberedListRegex =
        RegExp(r'\d+\.\s*(.*?)(?=\d+\.|$)', multiLine: true);
    final matches = numberedListRegex.allMatches(text);

    if (matches.isNotEmpty) {
      return matches
          .map((m) => m.group(1)?.trim() ?? "")
          .where((title) => title.isNotEmpty)
          .toList();
    }

    // Buscar listas con viñetas (- Título o * Título)
    final bulletListRegex =
        RegExp(r'[-*•]\s*(.*?)(?=[-*•]|$)', multiLine: true);
    final bulletMatches = bulletListRegex.allMatches(text);

    if (bulletMatches.isNotEmpty) {
      return bulletMatches
          .map((m) => m.group(1)?.trim() ?? "")
          .where((title) => title.isNotEmpty)
          .toList();
    }

    // Si todo falla, dividir por líneas y limpiar
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) =>
            line.isNotEmpty &&
            line.length > 3 &&
            !line.startsWith('{') &&
            !line.startsWith('}'))
        .toList();

    // Limitar a máximo 5 títulos
    return lines.length > 5 ? lines.sublist(0, 5) : lines;
  }

  // Función mejorada para limpiar la cadena JSON recibida
  String _cleanJsonString(String jsonString) {
    // Eliminar caracteres de backtick (`) y marcadores de código
    String cleaned = jsonString.replaceAll('```json', '').replaceAll('```', '');

    try {
      // Intentar encontrar el objeto JSON completo
      final RegExp jsonObjectRegex = RegExp(r'(\{[\s\S]*\})');
      final Match? objectMatch = jsonObjectRegex.firstMatch(cleaned);

      if (objectMatch != null && objectMatch.group(1) != null) {
        // Verificar si el JSON encontrado es válido
        final candidateJson = objectMatch.group(1)!;
        try {
          // Intenta analizar para validar que es JSON válido
          jsonDecode(candidateJson);
          return candidateJson;
        } catch (_) {
          // Si falla, continúa con el proceso de limpieza
        }
      }

      // Si no se encontró un objeto completo o no era JSON válido,
      // intentar con técnicas adicionales de limpieza

      // Eliminar espacios en blanco al inicio y al final
      cleaned = cleaned.trim();

      // Si no comienza con '{', buscarlo e iniciar desde ahí
      if (!cleaned.startsWith('{')) {
        final openBraceIndex = cleaned.indexOf('{');
        if (openBraceIndex >= 0) {
          cleaned = cleaned.substring(openBraceIndex);
        }
      }

      // Si no termina con '}', recortar hasta el último '}'
      if (!cleaned.endsWith('}')) {
        final lastCloseBraceIndex = cleaned.lastIndexOf('}');
        if (lastCloseBraceIndex >= 0) {
          cleaned = cleaned.substring(0, lastCloseBraceIndex + 1);
        }
      }

      // Verificar si ahora es JSON válido
      try {
        jsonDecode(cleaned);
      } catch (e) {
        // Si todavía no es válido, crear un JSON predeterminado con cualquier texto
        // que parezca un título en el contenido original
        final List<String> possibleTitles = _extractTitlesFromText(jsonString);
        return jsonEncode({"titles": possibleTitles});
      }
    } catch (e) {
      // Si hay algún error en el proceso de limpieza, crear un JSON vacío
      return '{"titles":[]}';
    }

    return cleaned;
  }

  // Método de respaldo en caso de problemas con la API
  List<String> getFallbackMovieTitles(String keyword) {
    final Map<String, List<String>> fallbackTitles = {
      'accion': [
        'Die Hard',
        'Mad Max: Fury Road',
        'John Wick',
        'The Dark Knight',
        'Mission: Impossible - Fallout'
      ],
      'comedia': [
        'Superbad',
        'The Hangover',
        'Bridesmaids',
        'Anchorman',
        'Dumb and Dumber'
      ],
      'drama': [
        'The Shawshank Redemption',
        'The Godfather',
        'Schindler\'s List',
        'Forrest Gump',
        'The Green Mile'
      ],
      'scifi': [
        'Blade Runner',
        'The Matrix',
        'Interstellar',
        'Arrival',
        'Ex Machina'
      ],
      'terror': [
        'The Shining',
        'Hereditary',
        'The Exorcist',
        'Get Out',
        'The Conjuring'
      ],
      'romance': [
        'The Notebook',
        'Before Sunrise',
        'Pride and Prejudice',
        'La La Land',
        'Eternal Sunshine of the Spotless Mind'
      ],
    };

    String category = 'drama'; // Categoría por defecto

    keyword = keyword.toLowerCase();
    if (keyword.contains('accion') ||
        keyword.contains('pelea') ||
        keyword.contains('aventura')) {
      category = 'accion';
    } else if (keyword.contains('comedia') ||
        keyword.contains('divertida') ||
        keyword.contains('humor')) {
      category = 'comedia';
    } else if (keyword.contains('ciencia ficcion') ||
        keyword.contains('futuro') ||
        keyword.contains('espacio')) {
      category = 'scifi';
    } else if (keyword.contains('terror') ||
        keyword.contains('miedo') ||
        keyword.contains('horror')) {
      category = 'terror';
    } else if (keyword.contains('romance') ||
        keyword.contains('amor') ||
        keyword.contains('romantica')) {
      category = 'romance';
    }

    return fallbackTitles[category]!;
  }
}