import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'perfil_completo_screen.dart';
import '../theme/app_colors.dart' as theme;

class ProfileScreen extends StatefulWidget {
  final String dni;

  const ProfileScreen({Key? key, required this.dni}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  bool _cargando = false;
  bool _esPrimeraVez = false;
  String? fotoUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.dni)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _telefonoController.text = data['telefono'] ?? '';
          _direccionController.text = data['direccion'] ?? '';
          fotoUrl = data['fotoUrl'];
          _esPrimeraVez =
              (data['telefono'] == null || data['telefono'].isEmpty) ||
              (data['direccion'] == null || data['direccion'].isEmpty);
        });
      }
    } catch (e) {
      print('Error al cargar datos: $e');
    }
  }

  Future<void> _actualizarDatos() async {
    final telefono = _telefonoController.text.trim();
    final direccion = _direccionController.text.trim();

    if (telefono.isEmpty || direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa ambos campos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.dni)
          .update({
        'telefono': telefono,
        'direccion': direccion,
        'fotoUrl': fotoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados correctamente ✅')),
      );

      if (_esPrimeraVez && mounted) {
        final snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.dni)
            .get();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PerfilCompletoScreen(userData: snapshot.data()!),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al actualizar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar datos')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    try {
      String storagePath = 'usuarios/${widget.dni}/perfil.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);

      UploadTask uploadTask;

      if (kIsWeb) {
        Uint8List fileBytes = await pickedFile.readAsBytes();
        uploadTask = ref.putData(fileBytes);
      } else {
        File file = File(pickedFile.path);
        uploadTask = ref.putFile(file);
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      setState(() {
        fotoUrl = downloadURL;
      });

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.dni)
          .update({'fotoUrl': downloadURL});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida correctamente ✅')),
      );
    } catch (e) {
      print('Error al subir la foto: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir la foto: $e')));
    }
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = theme.AppColors.primaryBlue;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente y decoraciones circulares
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              ),
            ),
          ),
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Completar Perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Caja blanca que ocupa toda la pantalla
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: fotoUrl != null
                                      ? NetworkImage(fotoUrl!)
                                      : null,
                                  child: fotoUrl == null
                                      ? const Icon(Icons.person, size: 60)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _seleccionarFoto,
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: primary,
                                      child: const Icon(Icons.edit,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Teléfono
                          TextField(
                            controller: _telefonoController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone, color: primary),
                              labelText: 'Teléfono',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dirección
                          TextField(
                            controller: _direccionController,
                            decoration: InputDecoration(
                              prefixIcon:
                                  Icon(Icons.location_on, color: primary),
                              labelText: 'Dirección',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Botón
                          _cargando
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _actualizarDatos,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      _esPrimeraVez
                                          ? 'Guardar y continuar'
                                          : 'Guardar cambios',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
