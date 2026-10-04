import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LavadorasPage extends StatefulWidget {
  const LavadorasPage({super.key});

  @override
  State<LavadorasPage> createState() => _LavadorasPageState();
}

class _LavadorasPageState extends State<LavadorasPage> {
  List lavadoras = [];
  bool cargando = true;
  String? errorMensaje;

  // IP especial para que el emulador de Android se conecte a Spring Boot
  final String apiUrl = "http://10.0.2.2:8080/api/lavadoras";

  @override
  void initState() {
    super.initState();
    obtenerLavadoras();
  }

  Future<void> obtenerLavadoras() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          lavadoras = json.decode(response.body);
          cargando = false;
          errorMensaje = null;
        });
      } else {
        // Intento alternativo sin prefijo /api si el backend no usa /api
        final responseAlt = await http.get(
          Uri.parse("http://10.0.2.2:8080/lavadoras"),
        );
        if (responseAlt.statusCode == 200) {
          setState(() {
            lavadoras = json.decode(responseAlt.body);
            cargando = false;
            errorMensaje = null;
          });
        } else {
          setState(() {
            errorMensaje = "Error del servidor: ${response.statusCode}";
            cargando = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMensaje =
            "No se pudo conectar al backend Spring Boot.\nAsegúrate de que el backend esté encendido.";
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          "Inventario de Lavadoras",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                cargando = true;
              });
              obtenerLavadoras();
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorMensaje != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorMensaje!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          cargando = true;
                        });
                        obtenerLavadoras();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reintentar"),
                    ),
                  ],
                ),
              ),
            )
          : lavadoras.isEmpty
          ? const Center(child: Text("No hay lavadoras registradas."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lavadoras.length,
              itemBuilder: (context, index) {
                final item = lavadoras[index];
                final String? imagenUrl = item['imagenUrl'] ?? item['imagen'];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.indigo.shade50,
                            child: imagenUrl != null && imagenUrl.isNotEmpty
                                ? Image.network(
                                    imagenUrl.replaceAll(
                                      "localhost",
                                      "10.0.2.2",
                                    ),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.local_laundry_service,
                                              size: 40,
                                              color: Colors.indigo,
                                            ),
                                  )
                                : const Icon(
                                    Icons.local_laundry_service,
                                    size: 40,
                                    color: Colors.indigo,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['marca'] ?? 'Sin marca',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Modelo: ${item['modelo'] ?? 'N/A'}",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              if (item['capacidad'] != null)
                                Text(
                                  "Capacidad: ${item['capacidad']} Kg",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                "\$${item['precio']?.toStringAsFixed(0) ?? item['precio']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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
    );
  }
}
