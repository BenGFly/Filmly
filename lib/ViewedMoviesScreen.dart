import 'package:flutter/material.dart';

class ViewedMoviesScreen extends StatelessWidget {
  const ViewedMoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Esta es solo una lista de ejemplo, deberías reemplazarla con las películas vistas almacenadas en tu base de datos o almacenamiento
    final List<String> viewedMovies = [
      'Inception',
      'The Dark Knight',
      'Avengers: Endgame',
      'Spider-Man: No Way Home',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Películas Vistas'),
        backgroundColor: Color(0xFF2C2C2C), // Gris oscuro
      ),
      body: viewedMovies.isEmpty
          ? const Center(
        child: Text(
          'Aún no has marcado ninguna película como vista.',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: viewedMovies.length,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            title: Text(
              viewedMovies[index], // Título de la película
              style: const TextStyle(fontSize: 18),
            ),
            trailing: const Icon(Icons.check, color: Colors.green), // Icono de "vista"
            onTap: () {
              // Aquí puedes añadir la lógica para ver más detalles de la película
            },
          );
        },
      ),
    );
  }
}
