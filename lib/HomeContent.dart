import 'package:filmly/MovieDetailsScreen.dart';
import 'package:flutter/material.dart';

class HomeContent extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController directorController;
  final String? selectedGenre;
  final List<String> genres;
  final Function() onSearch;
  final Function() onClearFilters;
  final bool isLoading;
  final List<dynamic> movies;
  final bool isLoadingMore;
  final Function(String?) onGenreChanged;
  final Function() loadMoreMovies;
  final double? selectedRating;
  final String? selectedDateFilter;
  final List<String> dateFilters;
  final Function(double?) onRatingChanged;
  final Function(String?) onDateFilterChanged;

  const HomeContent({
    super.key,
    required this.controller,
    required this.directorController,
    required this.selectedGenre,
    required this.genres,
    required this.onSearch,
    required this.onClearFilters,
    required this.isLoading,
    required this.movies,
    required this.isLoadingMore,
    required this.onGenreChanged,
    required this.loadMoreMovies,
    required this.selectedRating,
    required this.selectedDateFilter,
    required this.dateFilters,
    required this.onRatingChanged,
    required this.onDateFilterChanged,
  });

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _showFilters = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoadingMore) {
        widget.loadMoreMovies();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _showFilters = !_showFilters;
          });
        },
        backgroundColor: const Color(0xFFFF6347),
        icon: Icon(_showFilters ? Icons.close : Icons.filter_list, color: Colors.white),
        label: Text(
          _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.black],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Visibility(
              visible: _showFilters,
              child: SingleChildScrollView(
                child: Card(
                  elevation: 8,
                  color: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Reducir padding
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Evitar expansión vertical
                      children: [
                        // Campo de búsqueda
                        TextField(
                          controller: widget.controller,
                          decoration: _buildInputDecoration('Buscar película', Icons.movie),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: widget.directorController,
                          decoration: _buildInputDecoration('Buscar por director', Icons.person),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 8),

                        // Género
                        DropdownButtonFormField<String>(
                          value: widget.selectedGenre,
                          items: widget.genres.map((genre) => DropdownMenuItem(value: genre, child: Text(genre, style: _dropdownTextStyle))).toList(),
                          onChanged: widget.onGenreChanged,
                          decoration: _buildDropdownDecoration(Icons.category),
                          style: _dropdownTextStyle,
                          isDense: true, // Compactar dropdown
                        ),
                        const SizedBox(height: 8),

                        // Fecha
                        DropdownButtonFormField<String>(
                          value: widget.selectedDateFilter,
                          items: widget.dateFilters.map((dateFilter) => DropdownMenuItem(value: dateFilter, child: Text(dateFilter, style: _dropdownTextStyle))).toList(),
                          onChanged: widget.onDateFilterChanged,
                          decoration: _buildDropdownDecoration(Icons.calendar_today),
                          style: _dropdownTextStyle,
                          isDense: true,
                        ),
                        const SizedBox(height: 8),

                        // Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Rating mínimo:', style: TextStyle(color: Color(0xFFFF6347), fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(widget.selectedRating?.toStringAsFixed(1) ?? '0.0', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: widget.selectedRating ?? 0,
                          min: 0,
                          max: 10,
                          divisions: 100,
                          label: widget.selectedRating?.toStringAsFixed(1),
                          onChanged: widget.onRatingChanged,
                          activeColor: const Color(0xFFFF6347),
                          inactiveColor: Colors.grey,
                        ),
                        const SizedBox(height: 8),

                        // Botones compactos
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.onSearch,
                                style: _buildButtonStyle(),
                                child: const Text('Buscar',style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.onClearFilters,
                                style: _buildButtonStyle(),
                                child: const Text('Limpiar',style: TextStyle(color: Colors.white),),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.movies.isEmpty
                  ? const Center(
                child: Text(
                  'No se encontraron películas.',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              )
                  : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.75 : 0.65,  // Ajuste dinámico
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.movies.length + (widget.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == widget.movies.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final movie = widget.movies[index];
                  final posterUrl = movie['poster_path'] != null
                      ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
                      : 'assets/placeholder.png';

                                   return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailsScreen(movie: movie),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.grey[900],
                      child: Stack(
                        children: [
                          // Poster image with gradient overlay
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5, // Aumentar el espacio para la imagen
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Movie poster
                                      Image.network(
                                        posterUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/placeholder.png',
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                      // Gradient overlay on poster
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.7),
                                              ],
                                              stops: const [0.7, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Movie info section - más compacto
                              Expanded(
                                flex: 1, // Reducir el espacio para la información
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(15),
                                    ),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            movie['title'] ?? 'Sin título',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (constraints.maxHeight > 38)
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    color: Colors.grey[400],
                                                    size: 10,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    movie['release_date']?.split('-')[0] ?? 'N/A',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ],
    
                                              
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Rating chip
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRatingColor(movie['vote_average'] ?? 0),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 3,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: _getRatingColor(movie['vote_average'] ?? 0),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    movie['vote_average']?.toStringAsFixed(1) ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getRatingColor(movie['vote_average'] ?? 0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFFF6347), fontSize: 14),
      prefixIcon: Icon(icon, color: Color(0xFFFF6347)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    );
  }

  InputDecoration _buildDropdownDecoration(IconData icon) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      prefixIcon: Icon(icon, color: Color(0xFFFF6347)),
    );
  }

  TextStyle get _dropdownTextStyle => const TextStyle(color: Color(0xFFFF6347), fontSize: 14);

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 36), // Reducir altura del botón
      backgroundColor: const Color(0xFFFF6347),
    );
  }
  
  Color _getRatingColor(dynamic rating) {
    double numRating = rating is num ? rating.toDouble() : 0.0;
    if (numRating >= 8) return Colors.green;
    if (numRating >= 6) return Colors.amber;
    if (numRating >= 4) return Colors.orange;
    return Colors.red;
  }
}