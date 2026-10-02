import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TiendaLavadorasApp());
}

class TiendaLavadorasApp extends StatelessWidget {
  const TiendaLavadorasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tienda de Lavadoras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ----------------------------------------------------
// PANTALLA 1: INICIO DE SESIÓN (JWT AUTH)
// ----------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final String _baseUrl = "http://10.0.2.2:8080/api/auth/login";

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token'] ?? '';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LavadorasCatalogScreen(token: token),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión con el servidor: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_laundry_service, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    'Tienda de Lavadoras',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// PANTALLA 2: CATÁLOGO E INVENTARIO CON CRUD COMPLETO
// ----------------------------------------------------
class LavadorasCatalogScreen extends StatefulWidget {
  final String token;
  const LavadorasCatalogScreen({super.key, required this.token});

  @override
  State<LavadorasCatalogScreen> createState() => _LavadorasCatalogScreenState();
}

class _LavadorasCatalogScreenState extends State<LavadorasCatalogScreen> {
  List<dynamic> _lavadoras = [];
  bool _isLoading = true;

  final String _apiUrl = "http://10.0.2.2:8080/api/lavadoras";

  @override
  void initState() {
    super.initState();
    _fetchLavadoras();
  }

  // 1. OBTENER LISTA (READ)
  Future<void> _fetchLavadoras() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _lavadoras = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. CREAR / EDITAR LAVADORA (CREATE / UPDATE)
  Future<void> _showLavadoraForm({Map<String, dynamic>? lavadora}) async {
    final isEditing = lavadora != null;
    final marcaController = TextEditingController(text: isEditing ? lavadora['marca'].toString() : '');
    final modeloController = TextEditingController(text: isEditing ? lavadora['modelo'].toString() : '');
    final capacidadController = TextEditingController(text: isEditing ? lavadora['capacidad'].toString() : '');
    final cantidadController = TextEditingController(text: isEditing ? lavadora['cantidad'].toString() : '');
    final precioController = TextEditingController(text: isEditing ? lavadora['precio'].toString() : '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Lavadora' : 'Agregar Nueva Lavadora'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: marcaController,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                TextField(
                  controller: modeloController,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                TextField(
                  controller: capacidadController,
                  decoration: const InputDecoration(labelText: 'Capacidad (Kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Stock (Unidades)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio (\$)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final body = jsonEncode({
                  'marca': marcaController.text.trim(),
                  'modelo': modeloController.text.trim(),
                  'capacidad': double.tryParse(capacidadController.text) ?? 0,
                  'cantidad': int.tryParse(cantidadController.text) ?? 0,
                  'precio': double.tryParse(precioController.text) ?? 0.0,
                });

                final headers = {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${widget.token}',
                };

                http.Response response;
                if (isEditing) {
                  response = await http.put(
                    Uri.parse('$_apiUrl/${lavadora['id']}'),
                    headers: headers,
                    body: body,
                  );
                } else {
                  response = await http.post(
                    Uri.parse(_apiUrl),
                    headers: headers,
                    body: body,
                  );
                }

                if (mounted && (response.statusCode == 200 || response.statusCode == 201)) {
                  Navigator.pop(context);
                  _fetchLavadoras();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al guardar los datos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  // 3. ELIMINAR LAVADORA (DELETE)
  Future<void> _confirmDelete(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Lavadora'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('$_apiUrl/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          _fetchLavadoras();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo eliminar la lavadora'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de conexión: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Lavadoras'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lavadoras.isEmpty
          ? const Center(child: Text('No hay lavadoras registradas.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _lavadoras.length,
        itemBuilder: (context, index) {
          final item = _lavadoras[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(Icons.wash, color: Colors.indigo),
              ),
              title: Text(
                '${item['marca']} - ${item['modelo']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capacidad: ${item['capacidad'] ?? 'N/A'} Kg'),
                    Text('Stock disponible: ${item['cantidad']} unidades'),
                    const SizedBox(height: 4),
                    Text(
                      '\$${item['precio']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar',
                    onPressed: () => _showLavadoraForm(lavadora: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Eliminar',
                    onPressed: () => _confirmDelete(item['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => _showLavadoraForm(),
        tooltip: 'Agregar Lavadora',
        child: const Icon(Icons.add),
      ),
    );
  }
}