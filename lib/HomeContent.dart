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
  final ScrollController scrollController;

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
    required this.scrollController,
  });

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoadingMore) {
        widget.loadMoreMovies();
      }
    }
  }

// ...existing code...

  // Actualiza el método build() para ajustar la altura del panel de filtros
// Modifica el método build() para manejar mejor el teclado en landscape
// Modifica el método build para mejorar el manejo del panel de filtros
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final crossAxisCount = screenWidth > 600 ? 4 : (isLandscape ? 3 : 2);
    final isTablet = screenWidth > 600;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
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
              _showFilters ? Colors.grey[800] : const Color(0xFFFF6347),
          icon: Icon(
            _showFilters ? Icons.close : Icons.filter_list,
            color: Colors.white,
          ),
          label: Text(
            _showFilters ? 'Ocultar' : 'Filtrar',
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
            colors: [Colors.black87, Color(0xFF1A1A1A)],
          ),
        ),
        // Usar CustomScrollView para evitar problemas de overflow
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverToBoxAdapter(child: const SizedBox(height: 8)),

              // Panel de filtros ahora como SliverToBoxAdapter
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
                        shadowColor: const Color(0xFFFF6347).withOpacity(0.3),
                        color: Colors.grey[850],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: const Color(0xFFFF6347).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isLandscape ? 12.0 : 16.0),
                          child: isTablet
                              ? _buildTabletFilters()
                              : isLandscape
                                  ? _buildLandscapeFilters()
                                  : _buildMobileFilters(),
                        ),
                      ),
                    ),
                  ),
                ),

              // Contador de resultados
              if (widget.movies.isNotEmpty && !widget.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.movie_filter,
                            color: Color(0xFFFF6347), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Películas: ${widget.movies.length}',
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

              // Grid de películas
              widget.isLoading
                  ? SliverFillRemaining(
                      child: _buildLoadingIndicator(),
                    )
                  : widget.movies.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < widget.movies.length) {
                                  return _buildMovieCard(widget.movies[index]);
                                } else {
                                  return _buildLoadMoreIndicator();
                                }
                              },
                              childCount: widget.movies.length +
                                  (widget.isLoadingMore ? 1 : 0),
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
                        color: Color(0xFFFF6347)),
                    label: const Text('Cerrar teclado',
                        style: TextStyle(color: Color(0xFFFF6347))),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLandscapeFilters() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Si el teclado está abierto, usar una versión ultrasimplificada del filtro
    if (keyboardOpen) {
      return SingleChildScrollView(
        // Importante: envolver con SingleChildScrollView
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Importante: usar MainAxisSize.min
          children: [
            // Título de filtros - Esto debería ser visible ahora
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_alt, color: Color(0xFFFF6347), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Filtros', // Nombre más corto
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Botón para cerrar el teclado
                IconButton(
                  onPressed: () {
                    // Cerrar el teclado antes de ejecutar la acción de búsqueda
                    FocusScope.of(context).unfocus();
                    widget.onSearch();
                  },
                  icon: const Icon(Icons.keyboard_hide,
                      color: Color(0xFFFF6347), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Cerrar teclado',
                ),
              ],
            ),
            const Divider(color: Color(0xFFFF6347), thickness: 1, height: 12),

            // Solo mostrar los elementos más importantes en landscape con teclado
            _buildSearchField(widget.controller, 'Película', Icons.movie),

            const SizedBox(height: 8),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: _buildCompactActionButton(
                    'Buscar',
                    Icons.search,
                    widget.onSearch,
                    const Color(0xFFFF6347),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactActionButton(
                    'Limpiar',
                    Icons.clear_all,
                    widget.onClearFilters,
                    Colors.grey[700]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Diseño normal para landscape sin teclado (como lo tenías)
    return SingleChildScrollView(
      // También envolver con SingleChildScrollView
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // También usar MainAxisSize.min aquí
        children: [
          // Título de filtros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_alt, color: Color(0xFFFF6347), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Filtros de búsqueda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Botón de búsqueda en el título
              IconButton(
                onPressed: () {
                  // Cerrar el teclado antes de ejecutar la acción de búsqueda
                  FocusScope.of(context).unfocus();
                  widget.onSearch();
                },
                icon: const Icon(Icons.search, color: Color(0xFFFF6347)),
                tooltip: 'Buscar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Divider(color: Color(0xFFFF6347), thickness: 1, height: 16),

          // Layout optimizado para landscape (como lo tenías)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera columna: búsquedas
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Importante: MainAxisSize.min
                  children: [
                    _buildSearchField(
                        widget.controller, 'Buscar película', Icons.movie),
                    const SizedBox(height: 8),
                    _buildSearchField(
                        widget.directorController, 'Director', Icons.person),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Segunda columna: dropdown y slider
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Importante: MainAxisSize.min
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildGenreDropdown()),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDateDropdown()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCompactRatingSlider(),
                  ],
                ),
              ),

              // Tercera columna: botones
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min, // Importante: MainAxisSize.min
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCompactActionButton(
                    'Buscar',
                    Icons.search,
                    widget.onSearch,
                    const Color(0xFFFF6347),
                  ),
                  const SizedBox(height: 8),
                  _buildCompactActionButton(
                    'Limpiar',
                    Icons.clear_all,
                    widget.onClearFilters,
                    Colors.grey[700]!,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

// Añade este método a la clase
  Widget _buildKeyboardDismissButton() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (!keyboardOpen) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.small(
        backgroundColor: const Color(0xFFFF6347),
        onPressed: () => FocusScope.of(context).unfocus(),
        child: const Icon(Icons.keyboard_hide, color: Colors.white),
      ),
    );
  }

  Widget _buildTabletFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de filtros
        const Row(
          children: [
            Icon(Icons.filter_alt, color: Color(0xFFFF6347)),
            SizedBox(width: 8),
            Text(
              'Filtros de búsqueda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFFFF6347), thickness: 1, height: 24),

        // Layout en filas para tablet
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primera columna: texto y género
            Expanded(
              child: Column(
                children: [
                  _buildSearchField(
                      widget.controller, 'Buscar película', Icons.movie),
                  const SizedBox(height: 12),
                  _buildSearchField(widget.directorController,
                      'Buscar por director', Icons.person),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Segunda columna: dropdowns
            Expanded(
              child: Column(
                children: [
                  _buildGenreDropdown(),
                  const SizedBox(height: 12),
                  _buildDateDropdown(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rating slider
        _buildRatingSlider(),
        const SizedBox(height: 16),

        // Botones
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Buscar',
                Icons.search,
                widget.onSearch,
                const Color(0xFFFF6347),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Limpiar',
                Icons.clear_all,
                widget.onClearFilters,
                Colors.grey[700]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de filtros
        const Row(
          children: [
            Icon(Icons.filter_alt, color: Color(0xFFFF6347)),
            SizedBox(width: 8),
            Text(
              'Filtros de búsqueda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFFFF6347), thickness: 1, height: 24),

        // Layout en columna para móvil
        _buildSearchField(widget.controller, 'Buscar película', Icons.movie),
        const SizedBox(height: 12),
        _buildSearchField(
            widget.directorController, 'Buscar por director', Icons.person),
        const SizedBox(height: 12),
        _buildGenreDropdown(),
        const SizedBox(height: 12),
        _buildDateDropdown(),
        const SizedBox(height: 12),
        _buildRatingSlider(),
        const SizedBox(height: 16),

        // Botones
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Buscar',
                Icons.search,
                widget.onSearch,
                const Color(0xFFFF6347),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Limpiar',
                Icons.clear_all,
                widget.onClearFilters,
                Colors.grey[700]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(
      TextEditingController controller, String label, IconData icon) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Altura aún más reducida si el teclado está abierto en landscape
    final height = keyboardOpen && isLandscape
        ? 36
        : isLandscape
            ? 40
            : 48;

    return Container(
      height: height.toDouble(),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: Colors.white,
          fontSize: isLandscape ? 12 : 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: isLandscape ? 12 : 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFFF6347),
            size: isLandscape ? 16 : 18,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: isLandscape ? 6 : 12,
            horizontal: isLandscape ? 12 : 16,
          ),
          isDense: true, // Siempre más compacto
        ),
      ),
    );
  }

// Versión compacta del slider de rating
  Widget _buildCompactRatingSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rating mínimo:',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRatingColor(widget.selectedRating ?? 0)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getRatingColor(widget.selectedRating ?? 0),
                  width: 1,
                ),
              ),
              child: Text(
                (widget.selectedRating ?? 0.0).toStringAsFixed(1),
                style: TextStyle(
                  color: _getRatingColor(widget.selectedRating ?? 0),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 3,
            activeTrackColor: _getRatingColor(widget.selectedRating ?? 0),
            inactiveTrackColor: Colors.grey[800],
            thumbColor: _getRatingColor(widget.selectedRating ?? 0),
            overlayColor:
                _getRatingColor(widget.selectedRating ?? 0).withOpacity(0.2),
          ),
          child: Slider(
            value: widget.selectedRating ?? 0,
            min: 0,
            max: 10,
            divisions: 100,
            onChanged: widget.onRatingChanged,
          ),
        ),
      ],
    );
  }

// Botones más compactos para el modo landscape
  Widget _buildCompactActionButton(
      String label, IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: () {
        // Cerrar el teclado antes de ejecutar la acción de búsqueda
        FocusScope.of(context).unfocus();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        minimumSize: const Size(90, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

// También modifica los dropdowns para que sean más pequeños
  Widget _buildGenreDropdown() {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Container(
      height: isLandscape ? 40 : 48,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: widget.selectedGenre,
        items: widget.genres
            .map((genre) => DropdownMenuItem(
                  value: genre,
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: isLandscape ? 12 : 14,
                    ),
                  ),
                ))
            .toList(),
        onChanged: widget.onGenreChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.category,
            color: const Color(0xFFFF6347),
            size: isLandscape ? 16 : 18,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 8 : 16,
            vertical: isLandscape ? 8 : 12,
          ),
          isDense: isLandscape,
        ),
        style: TextStyle(
          color: Colors.white,
          fontSize: isLandscape ? 12 : 14,
        ),
        dropdownColor: Colors.grey[850],
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: const Color(0xFFFF6347),
          size: isLandscape ? 20 : 24,
        ),
        // Quitar esta línea o asegurarse que sea >= 48
        // itemHeight: isLandscape ? 40 : null,
      ),
    );
  }

  Widget _buildDateDropdown() {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Container(
      height: isLandscape ? 40 : 48,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: widget.selectedDateFilter,
        items: widget.dateFilters
            .map((date) => DropdownMenuItem(
                  value: date,
                  child: Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: isLandscape ? 12 : 14,
                    ),
                  ),
                ))
            .toList(),
        onChanged: widget.onDateFilterChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.calendar_today,
            color: const Color(0xFFFF6347),
            size: isLandscape ? 16 : 18,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 8 : 16,
            vertical: isLandscape ? 8 : 12,
          ),
          isDense: isLandscape,
        ),
        style: TextStyle(
          color: Colors.white,
          fontSize: isLandscape ? 12 : 14,
        ),
        dropdownColor: Colors.grey[850],
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: const Color(0xFFFF6347),
          size: isLandscape ? 20 : 24,
        ),
        // Quitar esta línea o asegurarse que sea >= 48
        // itemHeight: isLandscape ? 40 : null,
      ),
    );
  }

  Widget _buildRatingSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFF6347), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Rating mínimo:',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(widget.selectedRating ?? 0)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRatingColor(widget.selectedRating ?? 0),
                  width: 1,
                ),
              ),
              child: Text(
                (widget.selectedRating ?? 0.0).toStringAsFixed(1),
                style: TextStyle(
                  color: _getRatingColor(widget.selectedRating ?? 0),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackHeight: 4,
            activeTrackColor: _getRatingColor(widget.selectedRating ?? 0),
            inactiveTrackColor: Colors.grey[800],
            thumbColor: _getRatingColor(widget.selectedRating ?? 0),
            overlayColor:
                _getRatingColor(widget.selectedRating ?? 0).withOpacity(0.2),
          ),
          child: Slider(
            value: widget.selectedRating ?? 0,
            min: 0,
            max: 10,
            divisions: 100,
            onChanged: widget.onRatingChanged,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(dynamic rating) {
    double ratingValue;

    // Handle different types of input (num, double, int, etc.)
    if (rating is num) {
      ratingValue = rating.toDouble();
    } else {
      try {
        ratingValue = double.tryParse(rating.toString()) ?? 0.0;
      } catch (_) {
        ratingValue = 0.0;
      }
    }

    if (ratingValue >= 7.5) {
      return const Color(0xFF4CAF50); // Green for high ratings
    } else if (ratingValue >= 6.0) {
      return const Color(0xFFFFC107); // Yellow/amber for medium ratings
    } else if (ratingValue >= 4.0) {
      return const Color(0xFFFF9800); // Orange for below average
    } else {
      return const Color(0xFFF44336); // Red for poor ratings
    }
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: () {
        // Cerrar el teclado antes de ejecutar la acción de búsqueda
        FocusScope.of(context).unfocus();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          iconColor: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    // Detectamos si estamos en landscape para adaptar el tamaño
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Esto es crucial para evitar el overflow
        children: [
          SizedBox(
            // Contentedor con tamaño fijo para el CircularProgressIndicator
            height: isLandscape ? 40 : 50,
            width: isLandscape ? 40 : 50,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6347)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: isLandscape ? 12 : 20),
          Text(
            'Cargando películas...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: isLandscape ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Detectamos si estamos en landscape para adaptar el tamaño
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Versión ultra compacta si el teclado está abierto en landscape
    if (isLandscape && keyboardOpen) {
      return Center(
        child: SingleChildScrollView(
          // Añadimos scroll por si acaso
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Crucial para evitar overflow
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 36, // Tamaño reducido
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8), // Espaciado reducido
              Text(
                'No se encontraron películas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, // Texto más pequeño
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                // Usamos TextButton en lugar de ElevatedButton
                onPressed: widget.onClearFilters,
                icon: const Icon(Icons.refresh,
                    size: 14, color: Color(0xFFFF6347)),
                label: const Text(
                  'Reiniciar',
                  style: TextStyle(fontSize: 12, color: Color(0xFFFF6347)),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 24), // Tamaño mínimo reducido
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap, // Más compacto
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Versión normal para otros casos
    return Center(
      child: SingleChildScrollView(
        // Añadimos scroll para mayor seguridad
        child: Column(
          mainAxisSize: MainAxisSize.min, // Crucial para evitar overflow
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              size: isLandscape ? 60 : 70,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 20),
            Text(
              'No se encontraron películas',
              style: TextStyle(
                fontSize: isLandscape ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Intenta con otros filtros de búsqueda',
              style: TextStyle(
                fontSize: isLandscape ? 14 : 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onClearFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reiniciar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6347),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFFFF6347).withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieCard(dynamic movie) {
    // Este método debería contener el código existente para mostrar la tarjeta de película
    // Manteniendo la implementación actual para no cambiar la forma en que se muestran las películas
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
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
                                      movie['release_date']?.split('-')[0] ??
                                          'N/A',
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
  }
}
