import 'package:flutter/material.dart';
import '../theme/app_colors.dart' as theme;

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = theme.AppColors.primaryBlue;
    final Color accent = theme.AppColors.warningYellow;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
              ),
            ),
          ),
          // Burbujas decorativas
          Positioned(top: -40, right: -30, child: _buildBubble(130, accent.withOpacity(0.12))),
          Positioned(top: 150, left: -50, child: _buildBubble(180, primary.withOpacity(0.1))),
          Positioned(bottom: -70, right: -20, child: _buildBubble(220, Colors.white.withOpacity(0.06))),

          // Contenido principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bar_chart, size: 80, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  "Estadísticas",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Aquí se mostrarán gráficos e información\nsobre las alertas de la comunidad",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
