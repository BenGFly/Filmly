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
        icon: Icon(_showFilters ? Icons.close : Icons.filter_list,
            color: Colors.white),
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
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: widget.controller,
                        decoration: InputDecoration(
                          labelText: 'Buscar película (opcional)',
                          labelStyle: const TextStyle(color: Colors.black),
                          prefixIcon:
                              const Icon(Icons.movie, color: Color(0xFFFF6347)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: widget.directorController,
                        decoration: InputDecoration(
                          labelText: 'Buscar por director (opcional)',
                          labelStyle: const TextStyle(color: Colors.black),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFFFF6347)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: widget.selectedGenre,
                        hint: const Text(
                          'Seleccionar género',
                          style: TextStyle(color: Colors.black),
                        ),
                        items: widget.genres.map((String genre) {
                          return DropdownMenuItem<String>(
                            value: genre,
                            child: Text(genre,
                                style: TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        onChanged: widget.onGenreChanged,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.category,
                              color: Color(0xFFFF6347)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: widget.onSearch,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFFFF6347),
                        ),
                        child: const Text(
                          'Buscar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: widget.onClearFilters,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFFFF6347),
                        ),
                        child: const Text(
                          'Limpiar filtros',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: widget.movies.length +
                              (widget.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == widget.movies.length) {
                              return const Center(
                                  child: CircularProgressIndicator());
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
                                    builder: (context) =>
                                        MovieDetailsScreen(movie: movie),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          posterUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/placeholder.png',
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            movie['title'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow[700],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                movie['vote_average']
                                                        ?.toStringAsFixed(2) ??
                                                    'N/A',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Fecha de lanzamiento: ${movie['release_date'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
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
}
