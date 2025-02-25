import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Aquí se mostrarán tus películas favoritas.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}