import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart' as theme;

// 🔹 Fondo decorativo reutilizable
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

class PublicarAlertaScreen extends StatefulWidget {
  const PublicarAlertaScreen({Key? key}) : super(key: key);

  @override
  State<PublicarAlertaScreen> createState() => _PublicarAlertaScreenState();
}

class _PublicarAlertaScreenState extends State<PublicarAlertaScreen> {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _tipoSeleccionado;

  final String dniUsuario = "98765432";

  final List<String> tiposDeIncidente = [
    "Incendio",
    "Robo",
    "Accidente",
    "Violencia",
    "Sospechoso",
    "Otro",
  ];

  Future<String> _generarIdAlerta() async {
    final hoy = DateTime.now();
    final fechaStr = "${hoy.year}${hoy.month.toString().padLeft(2, '0')}${hoy.day.toString().padLeft(2, '0')}";

    final query = await _firestore
        .collection('alertas')
        .where('idAlerta', isGreaterThanOrEqualTo: "ALERTA-$fechaStr")
        .where('idAlerta', isLessThan: "ALERTA-${fechaStr}Z")
        .get();

    final numAlerta = (query.docs.length + 1).toString().padLeft(3, '0');
    return "ALERTA-$fechaStr-$numAlerta";
  }

  Future<void> _publicarAlerta() async {
    final texto = _textController.text.trim();
    if (texto.isEmpty || _tipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imagenBase64;
    try {
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        imagenBase64 = base64Encode(bytes);
      } else if (_selectedImageBytes != null) {
        imagenBase64 = base64Encode(_selectedImageBytes!);
      }

      final idAlerta = await _generarIdAlerta();

      await _firestore.collection('alertas').add({
        'idAlerta': idAlerta,
        'texto': texto,
        'imagenBase64': imagenBase64 ?? '',
        'fecha': Timestamp.now(),
        'dniUsuario': dniUsuario,
        'estado': 'pendiente',
        'tipo': _tipoSeleccionado,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Alerta $idAlerta publicada correctamente")),
      );

      setState(() {
        _textController.clear();
        _selectedImageFile = null;
        _selectedImageBytes = null;
        _tipoSeleccionado = null;
        _isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar la alerta: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editarAlerta(String docId, Map<String, dynamic> alerta) async {
    _textController.text = alerta['texto'] ?? '';
    _tipoSeleccionado = alerta['tipo'] ?? 'Otro';

    // Cargar imagen existente para poder mostrarla en el diálogo
    final imagenBase64 = alerta['imagenBase64'] as String?;
    if (imagenBase64 != null && imagenBase64.isNotEmpty) {
      _selectedImageBytes = base64Decode(imagenBase64);
      _selectedImageFile = null;
    } else {
      _selectedImageBytes = null;
      _selectedImageFile = null;
    }

    _mostrarDialogoNuevaAlerta(editar: true, docId: docId);
  }

  Future<void> _eliminarAlerta(String docId) async {
    await _firestore.collection('alertas').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Alerta eliminada.")));
  }

  void _mostrarDialogoNuevaAlerta({bool editar = false, String? docId}) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  if (kIsWeb) {
                    final bytes = await picked.readAsBytes();
                    setModalState(() {
                      _selectedImageBytes = bytes;
                      _selectedImageFile = null;
                    });
                  } else {
                    setModalState(() {
                      _selectedImageFile = File(picked.path);
                      _selectedImageBytes = null;
                    });
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error seleccionando imagen: $e")),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
              ),
              child: DecoratedBackground(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 12),
                        Text(editar ? "Editar Alerta" : "Nueva Alerta", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _tipoSeleccionado,
                          items: tiposDeIncidente.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                          decoration: InputDecoration(
                            labelText: "Tipo de incidente",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          onChanged: (val) => setModalState(() => _tipoSeleccionado = val),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: _textController,
                                maxLines: 4,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  hintText: "Describe lo que sucede...",
                                  border: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_selectedImageFile != null || _selectedImageBytes != null)
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _selectedImageFile != null
                                          ? Image.file(_selectedImageFile!, height: 70, width: 70, fit: BoxFit.cover)
                                          : Image.memory(_selectedImageBytes!, height: 70, width: 70, fit: BoxFit.cover),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        setModalState(() {
                                          _selectedImageFile = null;
                                          _selectedImageBytes = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: pickImage),
                                  const Icon(Icons.emoji_emotions_outlined, color: Colors.orange),
                                  const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : editar
                                  ? () async {
                                      String? imagenBase64;
                                      if (_selectedImageFile != null) {
                                        final bytes = await _selectedImageFile!.readAsBytes();
                                        imagenBase64 = base64Encode(bytes);
                                      } else if (_selectedImageBytes != null) {
                                        imagenBase64 = base64Encode(_selectedImageBytes!);
                                      } else {
                                        imagenBase64 = '';
                                      }

                                      await _firestore.collection('alertas').doc(docId).update({
                                        'texto': _textController.text,
                                        'tipo': _tipoSeleccionado,
                                        'imagenBase64': imagenBase64,
                                      });

                                      Navigator.pop(context);
                                    }
                                  : _publicarAlerta,
                          icon: const Icon(Icons.send),
                          label: Text(_isLoading ? "Publicando..." : (editar ? "Guardar cambios" : "Publicar alerta")),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.AppColors.warningYellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Card de alerta
  Widget _buildAlertaCard(String docId, Map<String, dynamic> alerta) {
    final fecha = (alerta['fecha'] as Timestamp?)?.toDate();
    final fechaFormateada = fecha != null
        ? "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}"
        : "";

    final tieneImagen = alerta['imagenBase64'] != null && (alerta['imagenBase64'] as String).isNotEmpty;
    final estado = (alerta['estado'] ?? 'pendiente').toString().toLowerCase();
    final tipo = alerta['tipo'] ?? 'Desconocido';

    Color estadoColor;
    switch (estado) {
      case 'resuelto':
        estadoColor = Colors.green;
        break;
      case 'rechazado':
        estadoColor = Colors.redAccent;
        break;
      default:
        estadoColor = Colors.amber;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black26.withOpacity(0.08), blurRadius: 5)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tieneImagen)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(alerta['imagenBase64']),
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: estadoColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text("Estado: ${estado[0].toUpperCase()}${estado.substring(1)}",
                            style: TextStyle(color: estadoColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(fechaFormateada, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text("🆔 ${alerta['idAlerta'] ?? 'Desconocido'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text("📍 Tipo: $tipo", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
                Text(
                  alerta['texto'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
                Text("👤 DNI: ${alerta['dniUsuario'] ?? 'No asignado'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent), onPressed: () => _editarAlerta(docId, alerta)),
                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent), onPressed: () => _eliminarAlerta(docId)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('alertas').orderBy('fecha', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final alertas = snapshot.data?.docs ?? [];
            if (alertas.isEmpty) {
              return const Center(child: Text("Aún no hay alertas publicadas.", style: TextStyle(color: Colors.white)));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 80),
              itemCount: alertas.length,
              itemBuilder: (context, index) {
                final doc = alertas[index];
                final alerta = doc.data() as Map<String, dynamic>;
                return _buildAlertaCard(doc.id, alerta);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevaAlerta,
        backgroundColor: theme.AppColors.warningYellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
