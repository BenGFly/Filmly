import 'package:flutter/material.dart';
import 'package:filmly/services/GeminiService.dart';
import 'package:filmly/MovieDetailsScreen.dart';
import 'package:filmly/tmdb_service.dart';

class AIRecommendationScreen extends StatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  _AIRecommendationScreenState createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends State<AIRecommendationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final TMDbService _tmdbService = TMDbService();

  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _errorMessage = '';
  int _loadedMovies = 0;
  bool _showFilters = true; // Visible por defecto

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    if (_promptController.text.trim().isEmpty) {
      _showSnackBar('Por favor, ingresa una descripción', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _errorMessage = '';
      _recommendations = [];
      _loadedMovies = 0;
    });

    try {
      final recommendations =
          await _geminiService.getMovieRecommendations(_promptController.text);

      setState(() {
        _recommendations = recommendations;
        _isSearching = false;
        _isLoading = false;
        _loadedMovies = recommendations.length;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _viewMovieDetails(Map<String, dynamic> movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      // Evitar que el teclado empuje el contenido
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      floatingActionButton: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _showFilters ? 0.9 : 1.0,
        child: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
            if (_showFilters) {
              FocusScope.of(context).unfocus();
            }
          },
          backgroundColor:
              _showFilters ? Colors.grey[800] : const Color(0xFFAD1FEA),
          icon: Icon(
            _showFilters ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          label: Text(
            _showFilters ? 'Ocultar' : 'Buscar',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 6,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Color(0xFF2C2C2C)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: const SizedBox(height: 8)),

              // Panel de búsqueda AI (visible por defecto)
              if (_showFilters)
                SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showFilters ? 1.0 : 0.0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24.0 : 8.0),
                      child: Card(
                        elevation: 8,
                        shadowColor: const Color(0xFFAD1FEA).withOpacity(0.3),
                        color: Colors.grey[850],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: const Color(0xFFAD1FEA).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isLandscape ? 12.0 : 16.0),
                          child: _buildAISearchPanel(
                              isLandscape, keyboardOpen, isTablet),
                        ),
                      ),
                    ),
                  ),
                ),

              // Contador de resultados
              if (_loadedMovies > 0 && !_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.movie_filter,
                            color: Color(0xFFAD1FEA), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Películas recomendadas: $_loadedMovies',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Resultados - películas o mensaje
              _isSearching
                  ? SliverFillRemaining(
                      child: _buildLoadingIndicator(),
                    )
                  : _errorMessage.isNotEmpty
                      ? SliverFillRemaining(
                          child: _buildErrorMessage(),
                        )
                      : _recommendations.isEmpty
                          ? SliverFillRemaining(
                              child: _buildEmptyState(),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return _buildMovieCard(
                                        _recommendations[index]);
                                  },
                                  childCount: _recommendations.length,
                                ),
                              ),
                            ),

              // Padding adicional al final
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 56),
              ),
            ],
          ),
        ),
      ),
      // Botón para cerrar el teclado
      bottomNavigationBar: keyboardOpen && _showFilters
          ? SafeArea(
              child: Container(
                height: 40,
                color: Colors.transparent,
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => FocusScope.of(context).unfocus(),
                    icon: const Icon(Icons.keyboard_hide,
                        color: Color(0xFFAD1FEA)),
                    label: const Text('Cerrar teclado',
                        style: TextStyle(color: Color(0xFFAD1FEA))),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAISearchPanel(
      bool isLandscape, bool keyboardOpen, bool isTablet) {
    // Diseño similar al HomeContent pero para IA
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del panel
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: const Color(0xFFAD1FEA),
              size: isLandscape && keyboardOpen ? 16 : 20,
            ),
            SizedBox(width: isLandscape && keyboardOpen ? 6 : 8),
            Text(
              'Búsqueda con IA (Gemini)',
              style: TextStyle(
                color: Colors.white,
                fontSize: isLandscape && keyboardOpen ? 14 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFFAD1FEA), thickness: 1, height: 16),

        // Texto de ayuda
        if (!keyboardOpen || !isLandscape)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Describe lo que buscas y la IA te recomendará películas similares',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isLandscape ? 12 : 14,
              ),
            ),
          ),

        // Campo de búsqueda
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFAD1FEA).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _promptController,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLandscape && keyboardOpen ? 12 : 14,
            ),
            maxLines: isLandscape && keyboardOpen ? 2 : 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: isLandscape && keyboardOpen
                  ? 'Ej: "Una película de ciencia ficción con robots..."'
                  : 'Ej: "Una película sobre un astronauta perdido en el espacio" o "Film noir con detectives"',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: isLandscape && keyboardOpen ? 11 : 14,
              ),
              prefixIcon: Icon(
                Icons.psychology,
                color: const Color(0xFFAD1FEA),
                size: isLandscape && keyboardOpen ? 18 : 24,
              ),
              border: InputBorder.none,
              contentPadding: isLandscape && keyboardOpen
                  ? const EdgeInsets.all(10)
                  : const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Buscar con IA',
                Icons.search,
                _getRecommendations,
                const Color(0xFFAD1FEA),
                isLandscape && keyboardOpen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Limpiar',
                Icons.clear_all,
                () {
                  setState(() {
                    _promptController.clear();
                  });
                },
                Colors.grey[700]!,
                isLandscape && keyboardOpen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed,
      Color color, bool isCompact) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () {
              // Cerrar teclado antes de ejecutar acción
              FocusScope.of(context).unfocus();
              onPressed();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        ),
        elevation: isCompact ? 3 : 4,
        disabledBackgroundColor: color.withOpacity(0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? 16 : 18, color: Colors.white),
          SizedBox(width: isCompact ? 6 : 8),
          Text(
            _isLoading && label == 'Buscar con IA' ? 'Buscando...' : label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Center(
      child: SingleChildScrollView(
        // Añadimos SingleChildScrollView para evitar overflow
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Para que ocupe solo el espacio necesario
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: isLandscape ? 40 : 56, // Reducir tamaño en landscape
                width: isLandscape ? 40 : 56,
                child: const CircularProgressIndicator(
                  color: Color(0xFFAD1FEA),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: isLandscape ? 16 : 24),
              Text(
                'Consultando a la IA...',
                textAlign: TextAlign.center, // Centro el texto por si es largo
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: isLandscape ? 14 : 16,
                ),
              ),
              SizedBox(height: isLandscape ? 4 : 8),
              Text(
                'Esto puede tomar unos segundos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: isLandscape ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Center(
      child: SingleChildScrollView(
        // Añadimos SingleChildScrollView para evitar overflow
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Para que ocupe solo el espacio necesario
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: isLandscape ? 40 : 48,
              ),
              SizedBox(height: isLandscape ? 12 : 16),
              Text(
                'Error al obtener recomendaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: isLandscape ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isLandscape ? 6 : 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: isLandscape ? 12 : 14,
                ),
              ),
              SizedBox(height: isLandscape ? 16 : 24),
              TextButton.icon(
                onPressed: _getRecommendations,
                icon: const Icon(Icons.refresh, color: Color(0xFFAD1FEA)),
                label: const Text(
                  'Intentar nuevamente',
                  style: TextStyle(color: Color(0xFFAD1FEA)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter,
              color: Colors.grey[600],
              size: isLandscape ? 48 : 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Describe lo que buscas',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: isLandscape ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 24 : 42,
              ),
              child: Text(
                isLandscape
                    ? 'Prueba con: "Películas de ciencia ficción" o "Comedias románticas"'
                    : 'Por ejemplo: "Películas de ciencia ficción con viajes en el tiempo" o "Comedias románticas ambientadas en París"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isLandscape ? 12 : 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_showFilters)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showFilters = true;
                  });
                },
                icon: const Icon(Icons.search),
                label: const Text('Buscar con IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD1FEA),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final posterPath = movie['poster_path'];
    final title = movie['title'] ?? 'Sin título';
    final releaseDate = movie['release_date'] ?? '';
    final year = releaseDate.isNotEmpty ? releaseDate.substring(0, 4) : '';
    final voteAverage = movie['vote_average'] ?? 0.0;
    final overview = movie['overview'] ?? 'No hay descripción disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFAD1FEA).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewMovieDetails(movie),
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFFAD1FEA).withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la película
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: posterPath != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w200$posterPath',
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 150,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white54,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 150,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.movie,
                            color: Colors.white54,
                            size: 40,
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
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (year.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          year,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Puntuación
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Descripción
                      Text(
                        overview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botón para ver detalles
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () => _viewMovieDetails(movie),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFAD1FEA),
                            side: const BorderSide(color: Color(0xFFAD1FEA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Ver detalles'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
