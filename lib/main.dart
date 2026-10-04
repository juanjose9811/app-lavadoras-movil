import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          primary: const Color(0xFF3F51B5),
          secondary: const Color(0xFF00BCD4),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        cardTheme: CardThemeData(
          elevation: 5,
          shadowColor: Colors.indigo.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA 1: INICIO DE SESIÓN CON DEGRADADO
// -----------------------------------------------------------------------------
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
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa usuario y contraseña')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token'] ?? '';

        String role = 'ROLE_CLIENTE';
        if (data['role'] != null) {
          role = data['role'].toString();
        } else if (data['roles'] != null &&
            (data['roles'] as List).isNotEmpty) {
          role = data['roles'][0].toString();
        } else if (username.toLowerCase().contains('admin')) {
          role = 'ROLE_ADMIN';
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              token: token,
              username: username,
              role: role,
            ),
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
          content: Text('Error de conexión con Spring Boot: $e'),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_laundry_service,
                        size: 56,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tienda de Lavadoras',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ingresa a tu cuenta',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.indigo,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.indigo,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL CON NAVEGACIÓN Y ESTADO COMPARTIDO DE PEDIDOS
// -----------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  final String token;
  final String username;
  final String role;

  const MainNavigationScreen({
    super.key,
    required this.token,
    required this.username,
    required this.role,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _carrito = [];
  final List<Map<String, dynamic>> _pedidos = [];

  bool get _isAdmin => widget.role.toUpperCase().contains('ADMIN');

  @override
  void initState() {
    super.initState();
    _fetchPedidosServidor();
  }

  Future<void> _fetchPedidosServidor() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/pedidos"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _pedidos.clear();
          _pedidos.addAll(data.cast<Map<String, dynamic>>());
        });
      }
    } catch (_) {}
  }

  void _agregarAlCarrito(Map<String, dynamic> lavadora) {
    setState(() {
      final index = _carrito.indexWhere((item) => item['id'] == lavadora['id']);
      if (index >= 0) {
        _carrito[index]['cantidadCarrito'] =
            (_carrito[index]['cantidadCarrito'] ?? 1) + 1;
      } else {
        final newItem = Map<String, dynamic>.from(lavadora);
        newItem['cantidadCarrito'] = 1;
        _carrito.add(newItem);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${lavadora['marca']} agregada al carrito'),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _eliminarDelCarrito(int index) {
    setState(() => _carrito.removeAt(index));
  }

  void _limpiarCarrito() {
    setState(() => _carrito.clear());
  }

  Future<void> _registrarPedido(Map<String, dynamic> nuevoPedido) async {
    setState(() {
      _pedidos.insert(0, nuevoPedido);
    });

    try {
      await http.post(
        Uri.parse("http://10.0.2.2:8080/api/pedidos"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(nuevoPedido),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> paginasAdmin = [
      CatalogoTab(
        token: widget.token,
        isAdmin: true,
        onAgregarCarrito: _agregarAlCarrito,
      ),
      GestionPedidosTab(
        token: widget.token,
        pedidos: _pedidos,
        isAdmin: true,
        usernameActual: widget.username,
        onActualizarPedidos: _fetchPedidosServidor,
      ),
    ];

    final List<Widget> paginasCliente = [
      CatalogoTab(
        token: widget.token,
        isAdmin: false,
        onAgregarCarrito: _agregarAlCarrito,
      ),
      CarritoTab(
        carrito: _carrito,
        username: widget.username,
        token: widget.token,
        onEliminarItem: _eliminarDelCarrito,
        onLimpiarCarrito: _limpiarCarrito,
        onPedidoRealizado: _registrarPedido,
      ),
      GestionPedidosTab(
        token: widget.token,
        pedidos: _pedidos,
        isAdmin: false,
        usernameActual: widget.username,
        onActualizarPedidos: _fetchPedidosServidor,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAdmin ? 'Panel Administrador' : 'Tienda de Lavadoras',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _isAdmin
                      ? Colors.redAccent.withOpacity(0.9)
                      : Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isAdmin ? 'ADMIN' : 'CLIENTE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isAdmin
          ? paginasAdmin[_currentIndex]
          : paginasCliente[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _isAdmin
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2),
                  label: 'Inventario',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Pedidos',
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Catálogo',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text('${_carrito.length}'),
                    isLabelVisible: _carrito.isNotEmpty,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: 'Carrito',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: 'Mis Pedidos',
                ),
              ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: CATÁLOGO Y GESTIÓN DE INVENTARIO (CON TARJETAS ESTILIZADAS)
// -----------------------------------------------------------------------------
class CatalogoTab extends StatefulWidget {
  final String token;
  final bool isAdmin;
  final Function(Map<String, dynamic>) onAgregarCarrito;

  const CatalogoTab({
    super.key,
    required this.token,
    required this.isAdmin,
    required this.onAgregarCarrito,
  });

  @override
  State<CatalogoTab> createState() => _CatalogoTabState();
}

class _CatalogoTabState extends State<CatalogoTab> {
  List<dynamic> _lavadoras = [];
  bool _isLoading = true;
  final String _apiUrl = "http://10.0.2.2:8080/api/lavadoras";

  @override
  void initState() {
    super.initState();
    _fetchLavadoras();
  }

  String _construirUrlImagen(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    String url = rawUrl.trim();
    if (url.contains("localhost")) {
      url = url.replaceAll("localhost", "10.0.2.2");
    }
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      if (!url.startsWith("/")) url = "/$url";
      url = "http://10.0.2.2:8080$url";
    }
    return url;
  }

  Widget _construirImagenWidget(String? rawUrl) {
    final String url = _construirUrlImagen(rawUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 85,
        height: 85,
        color: Colors.indigo.shade50,
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_laundry_service,
                  color: Colors.indigo,
                  size: 40,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              )
            : const Icon(
                Icons.local_laundry_service,
                color: Colors.indigo,
                size: 40,
              ),
      ),
    );
  }

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showLavadoraForm({Map<String, dynamic>? lavadora}) async {
    final isEditing = lavadora != null;
    final marcaController = TextEditingController(
      text: isEditing ? lavadora['marca'].toString() : '',
    );
    final modeloController = TextEditingController(
      text: isEditing ? lavadora['modelo'].toString() : '',
    );
    final capacidadController = TextEditingController(
      text: isEditing ? lavadora['capacidad'].toString() : '',
    );
    final cantidadController = TextEditingController(
      text: isEditing ? lavadora['cantidad'].toString() : '',
    );
    final precioController = TextEditingController(
      text: isEditing ? lavadora['precio'].toString() : '',
    );
    final imagenUrlController = TextEditingController(
      text: isEditing
          ? (lavadora['imagenUrl'] ?? lavadora['imagen'] ?? '').toString()
          : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEditing ? 'Editar Lavadora' : 'Agregar Lavadora',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  decoration: const InputDecoration(
                    labelText: 'Capacidad (Kg)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Stock (Unidades)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio (\$)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imagenUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL de la Imagen',
                    hintText: 'http://10.0.2.2:8080/uploads/foto.jpg',
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final body = jsonEncode({
                  'marca': marcaController.text.trim(),
                  'modelo': modeloController.text.trim(),
                  'capacidad': double.tryParse(capacidadController.text) ?? 0,
                  'cantidad': int.tryParse(cantidadController.text) ?? 0,
                  'precio': double.tryParse(precioController.text) ?? 0.0,
                  'imagenUrl': imagenUrlController.text.trim(),
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

                if (mounted &&
                    (response.statusCode == 200 ||
                        response.statusCode == 201)) {
                  Navigator.pop(context);
                  _fetchLavadoras();
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text(
          '¿Estás seguro de eliminar esta lavadora del inventario?',
        ),
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
      final response = await http.delete(
        Uri.parse('$_apiUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchLavadoras();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lavadoras.isEmpty
          ? const Center(
              child: Text(
                'No hay lavadoras disponibles.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _lavadoras.length,
              itemBuilder: (context, index) {
                final item = _lavadoras[index];
                final String? rawImagen = item['imagenUrl'] ?? item['imagen'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 6,
                  shadowColor: Colors.indigo.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        _construirImagenWidget(rawImagen),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['marca']} ${item['modelo']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capacidad: ${item['capacidad'] ?? 'N/A'} Kg',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Stock: ${item['cantidad']} unidades',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\$${item['precio']}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isAdmin)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showLavadoraForm(lavadora: item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(item['id']),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('Agregar'),
                            onPressed: () => widget.onAgregarCarrito(item),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              onPressed: () => _showLavadoraForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: CARRITO DE COMPRAS Y REGISTRO DE COMPRA DETALLADA
// -----------------------------------------------------------------------------
class CarritoTab extends StatelessWidget {
  final List<Map<String, dynamic>> carrito;
  final String username;
  final String token;
  final Function(int) onEliminarItem;
  final VoidCallback onLimpiarCarrito;
  final Function(Map<String, dynamic>) onPedidoRealizado;

  const CarritoTab({
    super.key,
    required this.carrito,
    required this.username,
    required this.token,
    required this.onEliminarItem,
    required this.onLimpiarCarrito,
    required this.onPedidoRealizado,
  });

  double get _total => carrito.fold(
    0,
    (sum, item) =>
        sum +
        ((double.tryParse(item['precio'].toString()) ?? 0.0) *
            (item['cantidadCarrito'] ?? 1)),
  );

  void _mostrarFactura(BuildContext context) {
    final String numFactura =
        "FACT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
    final String fecha = DateTime.now().toString().split('.')[0];

    final List<Map<String, dynamic>> listaItemsComprados = carrito.map((item) {
      final double precio = double.tryParse(item['precio'].toString()) ?? 0.0;
      final int cant = item['cantidadCarrito'] ?? 1;
      return {
        'idLavadora': item['id'],
        'marca': item['marca'],
        'modelo': item['modelo'],
        'cantidad': cant,
        'precioUnitario': precio,
        'subtotal': precio * cant,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Factura de Compra',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                numFactura,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                Text(
                  'Cliente: $username',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Fecha: $fecha',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Detalle de Productos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...carrito.map((item) {
                  final subtotal =
                      (double.tryParse(item['precio'].toString()) ?? 0.0) *
                      (item['cantidadCarrito'] ?? 1);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['cantidadCarrito']}x ${item['marca']} ${item['modelo']}',
                          ),
                        ),
                        Text(
                          '\$$subtotal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pagado:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$$_total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirmar Pago'),
              onPressed: () {
                final nuevoPedido = {
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'numFactura': numFactura,
                  'cliente': username,
                  'fecha': fecha,
                  'total': _total,
                  'estado': 'PENDIENTE',
                  'items': listaItemsComprados,
                };

                onPedidoRealizado(nuevoPedido);
                onLimpiarCarrito();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      '¡Pago procesado con éxito! Pedido registrado.',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carrito.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: carrito.length,
            itemBuilder: (context, index) {
              final item = carrito[index];
              final double precio =
                  double.tryParse(item['precio'].toString()) ?? 0.0;
              final int cantidad = item['cantidadCarrito'] ?? 1;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 4,
                shadowColor: Colors.indigo.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      '$cantidad',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  title: Text(
                    '${item['marca']} ${item['modelo']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Precio unitario: \$$precio'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${precio * cantidad}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onEliminarItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$$_total',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text(
                    'Confirmar y Generar Factura',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _mostrarFactura(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: GESTIÓN DE PEDIDOS CON DESGLOSE Y CAMBIO DE ESTADOS
// -----------------------------------------------------------------------------
class GestionPedidosTab extends StatefulWidget {
  final String token;
  final List<Map<String, dynamic>> pedidos;
  final bool isAdmin;
  final String usernameActual;
  final VoidCallback onActualizarPedidos;

  const GestionPedidosTab({
    super.key,
    required this.token,
    required this.pedidos,
    required this.isAdmin,
    required this.usernameActual,
    required this.onActualizarPedidos,
  });

  @override
  State<GestionPedidosTab> createState() => _GestionPedidosTabState();
}

class _GestionPedidosTabState extends State<GestionPedidosTab> {
  final List<String> _estadosDisponibles = [
    'PENDIENTE',
    'EN_ALMACEN',
    'EN_PROCESO',
    'ENVIADO',
    'ENTREGADO',
    'CANCELADO',
  ];

  Color _obtenerColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN_ALMACEN':
        return Colors.brown;
      case 'EN_PROCESO':
        return Colors.blue;
      case 'ENVIADO':
        return Colors.purple;
      case 'ENTREGADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _actualizarEstadoBackend(
    dynamic pedidoId,
    String nuevoEstado,
  ) async {
    try {
      await http.put(
        Uri.parse("http://10.0.2.2:8080/api/pedidos/$pedidoId/estado"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'estado': nuevoEstado}),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pedidosFiltrados = widget.isAdmin
        ? widget.pedidos
        : widget.pedidos
              .where((p) => p['cliente'] == widget.usernameActual)
              .toList();

    if (pedidosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              widget.isAdmin
                  ? 'No hay pedidos en el sistema.'
                  : 'No has realizado ninguna compra.',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onActualizarPedidos(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: pedidosFiltrados.length,
        itemBuilder: (context, index) {
          final pedido = pedidosFiltrados[index];
          final String estadoActual = pedido['estado'] ?? 'PENDIENTE';
          final List<dynamic> itemsComprados = pedido['items'] ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 5,
            shadowColor: Colors.indigo.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              leading: Icon(
                Icons.receipt,
                color: _obtenerColorEstado(estadoActual),
                size: 28,
              ),
              title: Text(
                'Pedido #${pedido['id']} ${pedido['numFactura'] != null ? '(${pedido['numFactura']})' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Cliente: ${pedido['cliente']} | Total: \$${pedido['total']}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _obtenerColorEstado(estadoActual),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  estadoActual,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de Compra: ${pedido['fecha']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Productos Comprados:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Divider(),
                      if (itemsComprados.isEmpty)
                        const Text(
                          'Sin detalles de productos registrados.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        )
                      else
                        ...itemsComprados.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item['cantidad']}x ${item['marca']} ${item['modelo']}',
                                ),
                                Text(
                                  '\$${item['subtotal'] ?? (item['precioUnitario'] * item['cantidad'])}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const Divider(),
                      if (widget.isAdmin) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Modificar Estado:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: _estadosDisponibles.contains(estadoActual)
                                  ? estadoActual
                                  : _estadosDisponibles.first,
                              items: _estadosDisponibles.map((String estado) {
                                return DropdownMenuItem<String>(
                                  value: estado,
                                  child: Text(
                                    estado,
                                    style: TextStyle(
                                      color: _obtenerColorEstado(estado),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (nuevoEstado) {
                                if (nuevoEstado != null) {
                                  setState(() {
                                    pedido['estado'] = nuevoEstado;
                                  });
                                  _actualizarEstadoBackend(
                                    pedido['id'],
                                    nuevoEstado,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Pedido #${pedido['id']} actualizado a $nuevoEstado',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
