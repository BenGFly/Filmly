# Filmly

Una aplicación móvil para descubrir y explorar películas utilizando Flutter y APIs modernas.

## Características

- Búsqueda avanzada de películas por título, género, director y calificación
- Búsqueda con IA impulsada por Gemini (Google AI)
- Recomendaciones personalizadas basadas en descripciones de texto
- Diseño adaptativo para dispositivos móviles y tablets
- Modo oscuro integrado
- Experiencia de usuario fluida y moderna

## Tecnologías utilizadas

- Flutter para el desarrollo multiplataforma
- APIs de The Movie Database (TMDb) para la información de películas
- Gemini API para las recomendaciones basadas en IA
- Arquitectura limpia con principios SOLID

## Configuración

1. Clona el repositorio
2. Instala las dependencias:
flutter pub get
3. Configura las claves de API:
- Crea un archivo `.env` en la raíz del proyecto con el siguiente formato:
SUPABASE_URL=tu_supabase_url

SUPABASE_ANON_KEY=tu_supabase_anon_key

TMDB_API_KEY=tu_tmdb_api_key

TMDB_BASE_URL=https://api.themoviedb.org/3

GEMINI_API_KEY=tu_gemini_api_key

4. Ejecuta la aplicación:
flutter run

## Estructura del proyecto

- `lib/`: Código fuente principal
  - `services/`: Servicios para comunicación con APIs
  - `screens/`: Pantallas principales de la aplicación
  - `widgets/`: Componentes reutilizables
  - `models/`: Modelos de datos
  - `utils/`: Utilidades y helpers

## Notas de desarrollo

- La aplicación está optimizada para Android y iOS
- Diseño responsivo para diferentes tamaños de pantalla y orientaciones
- Soporte para modo oscuro y personalización visual

## Privacidad y seguridad

Para proteger tus claves de API, asegúrate de:

1. Añadir `.env` a tu archivo `.gitignore`
2. Nunca compartir tus claves de API en repositorios públicos
3. Usar variables de entorno para la configuración de producción
## Obtención de APIs necesarias

Para utilizar esta aplicación, necesitarás:

1. **Cuenta y API key de TMDb**: Regístrate en [The Movie Database](https://www.themoviedb.org/signup) y obtén tu API key en la sección de configuración.

2. **API key de Gemini**: Visita [Google AI Studio](https://aistudio.google.com/) para obtener acceso a la API de Gemini.

3. **Cuenta de Supabase** (opcional): Si deseas utilizar funcionalidades de backend, crea una cuenta en [Supabase](https://supabase.com/) y obtén tu URL y llave anónima.
