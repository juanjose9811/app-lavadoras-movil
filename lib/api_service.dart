import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LavadorasPage(),
    );
  }
}

class LavadorasPage extends StatefulWidget {
  const LavadorasPage({super.key});

  @override
  State<LavadorasPage> createState() => _LavadorasPageState();
}

class _LavadorasPageState extends State<LavadorasPage> {
  List lavadoras = [];

  @override
  void initState() {
    super.initState();
    obtenerLavadoras();
  }

  Future<void> obtenerLavadoras() async {
    final url = Uri.parse(
      "http://localhost/tienda_lavadoras_v2/get_lavadoras.php",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        lavadoras = json.decode(response.body);
      });
    } else {
      print("Error al cargar datos");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventario de Lavadoras")),
      body: lavadoras.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: lavadoras.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.local_laundry_service),
                  title: Text(lavadoras[index]['marca']),
                  subtitle: Text(
                    "Modelo: ${lavadoras[index]['modelo']} - \$${lavadoras[index]['precio']}",
                  ),
                );
              },
            ),
    );
  }
}
