import 'package:filmly/ViewedMoviesScreen.dart';
import 'package:flutter/material.dart';
import 'tmdb_service.dart';
import 'FavoritesScreen.dart';
import 'SettingsScreen.dart';
import 'HomeContent.dart'; // Importa el nuevo archivo

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  List<dynamic> _movies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  String? _selectedGenre;
  double? _selectedRating;
  String? _selectedDateFilter;

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
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _selectedGenre = 'Cualquier género';
    _selectedDateFilter = "Siempre";
    _loadNowPlayingMovies();
    _scrollController.addListener(_scrollListener);

    _screens.add(
      HomeContent(
        controller: _controller,
        directorController: _directorController,
        selectedGenre: _selectedGenre,
        genres: _genres,
        onSearch: _searchMovies,
        onClearFilters: _clearFilters,
        isLoading: _isLoading,
        movies: _movies,
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
        isLoadingMore: _isLoadingMore,
        onGenreChanged: (String? value) {
          setState(() {
            _selectedGenre = value;
          });
        },
        loadMoreMovies: _loadMoreMovies,
      ),
    );
    _screens.add(const FavoritesScreen());
    _screens.add(const SettingsScreen());
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar películas recientes: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar películas: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar más películas: $e')),
      );
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6347), Color(0xFFFF6F61)], // Naranja cálido
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: SizedBox(
          child: Image.asset(
            'assets/logo/logo_sin_bg.png', // Ruta de la imagen en los assets
            height: 60,

          ),
        ),
        centerTitle: true,
        backgroundColor: Colors
            .transparent, // Fondo transparente para que se vea el gradiente
      ),
      body: IndexedStack(
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ), // Blanco
            label: 'Inicio',
            backgroundColor: Color(0xFF2C2C2C),

          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite,
            ), // Verde lima
            label: 'Favoritas',
            backgroundColor: Color(0xFF2C2C2C),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.visibility,
            ), // Gris claro
            label: 'Peliculas vistas',
            backgroundColor: Color(0xFF2C2C2C),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ), // Gris claro
            label: 'Ajustes',
            backgroundColor: Color(0xFF2C2C2C),
          ),
        ],
        backgroundColor: Color(0xFF2C2C2C),
        // Gris oscuro
        unselectedItemColor: Color(0xFF8A8A8A),
        // Gris medio para íconos no seleccionados
        selectedItemColor: Color(0xFFFF6347),
        // Verde lima para íconos seleccionados
        selectedIconTheme:
            const IconThemeData(size: 28, color: Color(0xFFFF6347)),
        // Verde lima
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
