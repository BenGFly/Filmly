import 'package:filmly/ViewedMoviesScreen.dart';
import 'package:flutter/material.dart';
import 'tmdb_service.dart';
import 'FavoritesScreen.dart';
import 'SettingsScreen.dart';
import 'HomeContent.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  List<dynamic> _movies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  String? _selectedGenre;
  double? _selectedRating;
  String? _selectedDateFilter;

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
  final List<String> _screenTitles = ['Explora', 'Favoritas', 'Vistas', 'Ajustes'];

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
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
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
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreMovies();
    }
  }

  void _loadNowPlayingMovies() async {
    setState(() {
      _isLoading = true;
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
      _currentPage = 1;
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
      setState(() {
        _movies = movies;
      });
    } catch (e) {
      _showErrorSnackbar('Error al buscar películas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMoreMovies() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final tmdbService = TMDbService();
      final movies = await tmdbService.searchMovies(
        query: _controller.text.isEmpty ? null : _controller.text,
        director:
            _directorController.text.isEmpty ? null : _directorController.text,
        genre: _selectedGenre == 'Cualquier género' ? null : _selectedGenre,
        page: _currentPage + 1,
        rating: _selectedRating,
        dateFilter: _selectedDateFilter,
      );

      if (movies.isNotEmpty) {
        setState(() {
          _movies.addAll(movies);
          _currentPage++;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar más películas: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extender el contenido detrás del AppBar
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
                movies: _movies,
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
        elevation: 0, // Quitar sombra default
        backgroundColor: Colors.transparent, // Fondo transparente
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavigationBarItem(Icons.explore, 'Explorar', 0),
          _buildNavigationBarItem(Icons.favorite, 'Favoritas', 1),
          _buildNavigationBarItem(Icons.visibility, 'Vistas', 2),
          _buildNavigationBarItem(Icons.settings, 'Ajustes', 3),
        ],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: _getThemeColorForIndex(_selectedIndex), // Color dinámico según la sección
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(IconData icon, String label, int index) {
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
        return Icons.settings;
      default:
        return Icons.explore;
    }
  }
}