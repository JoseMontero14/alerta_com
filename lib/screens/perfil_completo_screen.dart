import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../theme/app_colors.dart' as theme;

// 🔹 Fondo decorativo reutilizable (igual que en PublicarAlerta)
class DecoratedBackground extends StatelessWidget {
  final Widget child;
  const DecoratedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Color primary = theme.AppColors.primaryBlue;
    final Color accent = theme.AppColors.warningYellow;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
            ),
          ),
        ),
        Positioned(top: -40, right: -30, child: _buildBubble(130, accent.withOpacity(0.12))),
        Positioned(top: 150, left: -50, child: _buildBubble(180, primary.withOpacity(0.1))),
        Positioned(bottom: -70, right: -20, child: _buildBubble(220, Colors.white.withOpacity(0.06))),
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildBubble(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class PerfilCompletoScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PerfilCompletoScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<PerfilCompletoScreen> createState() => _PerfilCompletoScreenState();
}

class _PerfilCompletoScreenState extends State<PerfilCompletoScreen> {
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    userData = Map<String, dynamic>.from(widget.userData);
  }

  Future<void> _refreshUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userData['dni'])
          .get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data()!;
        });
      }
    } catch (e) {
      debugPrint('Error al refrescar datos: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí, salir"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = theme.AppColors.warningYellow;

    return Scaffold(
      body: DecoratedBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 🔹 Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_pin_circle, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Mi Perfil",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 🔹 Contenido desplazable
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: accent.withOpacity(0.2),
                          backgroundImage: userData['fotoUrl'] != null
                              ? NetworkImage(userData['fotoUrl'])
                              : null,
                          child: userData['fotoUrl'] == null
                              ? const Icon(Icons.person, color: Colors.black54, size: 60)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['nombreCompleto'] ?? 'Usuario sin nombre',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Tarjetas compactas de info
                        _buildInfoRow(Icons.badge, "DNI", userData['dni']),
                        _buildInfoRow(Icons.phone, "Teléfono", userData['telefono']),
                        _buildInfoRow(Icons.home, "Dirección", userData['direccion']),
                        const SizedBox(height: 25),

                        // 🔹 Botones
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(dni: userData['dni']),
                              ),
                            );
                            await _refreshUserData();
                          },
                          icon: const Icon(Icons.edit, color: Colors.black),
                          label: const Text("Editar Perfil",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text("Cerrar Sesión",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Widget de fila compacta para mostrar datos
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.AppColors.primaryBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: ${value ?? 'No registrado'}",
              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
