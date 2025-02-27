import 'package:filmly/ViewedMoviesScreen.dart';
import 'package:flutter/material.dart';
import 'tmdb_service.dart';
import 'FavoritesScreen.dart';
import 'SettingsScreen.dart';
import 'HomeContent.dart';
import 'AIRecommendationScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  List<dynamic> _movies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  String? _selectedGenre;
  double? _selectedRating;
  String? _selectedDateFilter;
  DateTime? _lastInfoMessageTime;
  String _lastInfoMessage = '';
  bool _canLoadMore = true; // Para controlar si aún podemos cargar más
  // Controlador para las animaciones de transición
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _dateFilters = [
    'Siempre',
    'Hace 1 mes',
    'Hace 1 año',
  ];

  final List<String> _genres = [
    'Cualquier género',
    'Acción',
    'Aventura',
    'Comedia',
    'Drama',
    'Fantasía',
    'Terror',
    'Ciencia ficción',
    'Animación',
    'Documental',
  ];
  final ScrollController _scrollController = ScrollController();

  int _selectedIndex = 0;
  final List<String> _screenTitles = [
    'Explora',
    'Favoritas',
    'Vistas',
    'IA Cinéfila',
    'Ajustes'
  ];

  @override
  void initState() {
    super.initState();
    _selectedGenre = 'Cualquier género';
    _selectedDateFilter = "Siempre";
    _loadNowPlayingMovies();
    _scrollController.addListener(_scrollListener);

    // Configurar la animación de transición
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore &&
        _canLoadMore) {
      // Verificar _canLoadMore
      _loadMoreMovies();
    }
  }

  void _loadMoreMovies() async {
    if (_isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final tmdbService = TMDbService();
      final nextPage = _currentPage + 1;

      List<dynamic> newMovies;

      // If we're searching with filters, use the search endpoint
      if (_controller.text.isNotEmpty ||
          _directorController.text.isNotEmpty ||
          (_selectedGenre != null && _selectedGenre != 'Cualquier género') ||
          _selectedRating != null ||
          (_selectedDateFilter != null && _selectedDateFilter != 'Siempre')) {
        newMovies = await tmdbService.searchMovies(
          query: _controller.text.isEmpty ? null : _controller.text,
          director: _directorController.text.isEmpty
              ? null
              : _directorController.text,
          genre: _selectedGenre == 'Cualquier género' ? null : _selectedGenre,
          page: nextPage,
          rating: _selectedRating,
          dateFilter: _selectedDateFilter,
        );
      }
      // Otherwise load now playing movies
      else {
        newMovies = await tmdbService.getNowPlayingMovies(page: nextPage);
      }

      if (newMovies.isNotEmpty) {
        setState(() {
          // Filtrar duplicados antes de añadir las nuevas películas
          final Set<int> existingIds =
              _movies.map<int>((movie) => movie['id']).toSet();
          final List<dynamic> uniqueNewMovies = newMovies
              .where((movie) => !existingIds.contains(movie['id']))
              .toList();

          // Si hay películas nuevas únicas, añadirlas y actualizar la página
          if (uniqueNewMovies.isNotEmpty) {
            _movies.addAll(uniqueNewMovies);
            _currentPage = nextPage;
          } else {
            // Si todas las nuevas películas son duplicados, mostrar mensaje
            _showInfoSnackbar('No se encontraron más películas únicas');
            _canLoadMore = false; // Detener futuros intentos
          }
        });
      } else {
        // Si la API devuelve una lista vacía
        _showInfoSnackbar('No hay más películas disponibles');
        _canLoadMore = false; // Detener futuros intentos
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar más películas: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

// Añade este método para mostrar mensajes informativos
  void _showInfoSnackbar(String message) {
    final now = DateTime.now();

    // Comprobar si es el mismo mensaje y si ha pasado suficiente tiempo
    // Solo mostrar el mensaje si:
    // 1. Es un mensaje diferente al último, o
    // 2. Han pasado al menos 5 segundos desde el último mensaje idéntico
    if (_lastInfoMessageTime == null ||
        message != _lastInfoMessage ||
        now.difference(_lastInfoMessageTime!).inSeconds > 5) {
      // Actualizar el tiempo y mensaje
      _lastInfoMessageTime = now;
      _lastInfoMessage = message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _loadNowPlayingMovies() async {
    setState(() {
      _isLoading = true;
      _canLoadMore = true; // Resetear esta variable
    });

    try {
      final tmdbService = TMDbService();
      final movies = await tmdbService.getNowPlayingMovies(page: 1);
      setState(() {
        _movies = movies;
        _currentPage = 1;
      });
    } catch (e) {
      _showErrorSnackbar('Error al cargar películas recientes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchMovies() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1; // Reiniciar la paginación
      _canLoadMore = true; // Resetear esta variable
    });

    try {
      final tmdbService = TMDbService();
      final movies = await tmdbService.searchMovies(
        query: _controller.text.isEmpty ? null : _controller.text,
        director:
            _directorController.text.isEmpty ? null : _directorController.text,
        genre: _selectedGenre == 'Cualquier género' ? null : _selectedGenre,
        page: _currentPage,
        rating: _selectedRating,
        dateFilter: _selectedDateFilter,
      );

      // Asegurarse de que no hay duplicados (aunque aquí es menos probable porque es la primera página)
      final uniqueMovies = movies.toSet().toList();

      setState(() {
        _movies = uniqueMovies;
      });

      // Mostrar mensaje si no hay resultados
      if (uniqueMovies.isEmpty) {
        _showInfoSnackbar('No se encontraron películas con estos criterios');
      }
    } catch (e) {
      _showErrorSnackbar('Error al buscar películas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _controller.clear();
      _directorController.clear();
      _selectedGenre = 'Cualquier género';
      _selectedRating = null;
      _selectedDateFilter = "Siempre";
      _movies = [];
      _canLoadMore = true; // Resetear esta variable
    });
    _loadNowPlayingMovies();
  }

  void _onItemTapped(int index) {
    // Solo animar si cambiamos de pantalla
    if (_selectedIndex != index) {
      _animationController.reset();
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
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

// Y al pagar más películas:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Color(0xFF2C2C2C)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeContent(
                controller: _controller,
                directorController: _directorController,
                selectedGenre: _selectedGenre,
                genres: _genres,
                onSearch: _searchMovies,
                onClearFilters: _clearFilters,
                dateFilters: _dateFilters,
                selectedDateFilter: _selectedDateFilter,
                scrollController: _scrollController,
                movies: _movies,
                onDateFilterChanged: (String? value) {
                  setState(() {
                    _selectedDateFilter = value;
                  });
                },
                selectedRating: _selectedRating,
                onRatingChanged: (double? value) {
                  setState(() {
                    _selectedRating = value;
                  });
                },
                isLoading: _isLoading,
                isLoadingMore: _isLoadingMore,
                onGenreChanged: (String? value) {
                  setState(() {
                    _selectedGenre = value;
                  });
                },
                loadMoreMovies: _loadMoreMovies,
              ),
              const FavoritesScreen(),
              const ViewedMoviesScreen(),
              const AIRecommendationScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animado con rebote suave
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Image.asset(
                // Usar el logo con colores claros si está disponible
                // Si no, usar el logo original
                'assets/logo/logo_sin_bg.png',
                height: 35,
                // Aplicar un filtro de color para hacerlo más visible
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Título de la sección actual
          if (_selectedIndex > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getThemeColorForIndex(_selectedIndex).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getThemeColorForIndex(_selectedIndex),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForIndex(_selectedIndex),
                    color: _getThemeColorForIndex(_selectedIndex),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _screenTitles[_selectedIndex],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavigationBarItem(Icons.explore, 'Explorar', 0),
          _buildNavigationBarItem(Icons.favorite, 'Favoritas', 1),
          _buildNavigationBarItem(Icons.visibility, 'Vistas', 2),
          _buildNavigationBarItem(Icons.auto_awesome, 'IA', 3), // Nuevo ícono
          _buildNavigationBarItem(Icons.settings, 'Ajustes', 4),
        ],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: _getThemeColorForIndex(_selectedIndex),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
      IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = _getThemeColorForIndex(index);

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Colors.grey,
          size: isSelected ? 24 : 22,
        ),
      ),
      label: label,
      backgroundColor: Colors.transparent,
    );
  }

  Color _getThemeColorForIndex(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFF6347); // Naranja para Home
      case 1:
        return const Color(0xFFFF6347); // Rojo para Favoritos
      case 2:
        return const Color(0xFF3CB371); // Verde para Vistos
      case 3:
        return const Color(0xFFAD1FEA); // Púrpura para IA
      case 4:
        return const Color(0xFF64B5F6); // Azul para Ajustes
      default:
        return const Color(0xFFFF6347); // Default
    }
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.explore;
      case 1:
        return Icons.favorite;
      case 2:
        return Icons.visibility;
      case 3:
        return Icons.auto_awesome; // Nuevo ícono para IA
      case 4:
        return Icons.settings;
      default:
        return Icons.explore;
    }
  }
}
