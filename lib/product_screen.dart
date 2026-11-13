import 'package:flutter/material.dart';
import 'main.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  List<dynamic> _productos = [];
  List<dynamic> _categorias = [];
  List<dynamic> _proveedores = [];

  bool _isLoading = false;
  String? _selectedProdCodigo;
  
  String? _selectedCategoriaId;
  String? _selectedProveedorId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final resProd = await supabase.from('productos').select().order('prod_codigo', ascending: true);
      final resCat = await supabase.from('categoria').select();
      final resProv = await supabase.from('proveedores').select();

      setState(() {
        _productos = (resProd as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
        _categorias = (resCat as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
        _proveedores = (resProv as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();

        if (_categorias.isNotEmpty) _selectedCategoriaId = _categorias[0]['idcategoria'];
        if (_proveedores.isNotEmpty) _selectedProveedorId = _proveedores[0]['prov_cod'];

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar datos: $e', Colors.redAccent);
    }
  }

  Future<void> _grabar() async {
    final descripcion = _descripcionController.text.trim();
    final precio = double.tryParse(_precioController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (descripcion.isEmpty || _selectedCategoriaId == null || _selectedProveedorId == null) {
      _mostrarMensaje('Complete la descripción, categoría y proveedor', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resMax = await supabase
          .from('productos')
          .select('prod_codigo')
          .order('prod_codigo', ascending: false)
          .limit(1);

      String nuevoCodigo = 'P0001';
      if ((resMax as List).isNotEmpty) {
        String ultimoCod = resMax[0]['prod_codigo'].toString();
        int num = int.parse(ultimoCod.substring(1)) + 1;
        nuevoCodigo = 'P${num.toString().padLeft(4, '0')}';
      }

      await supabase.from('productos').insert({
        'prod_codigo': nuevoCodigo,
        'prod_nombre': descripcion.toUpperCase(),
        'prod_precio': precio,
        'prod_stock': stock,
        'idcategoria': _selectedCategoriaId,
        'prov_cod': _selectedProveedorId,
      });

      _nuevo();
      _cargarDatos();
      _mostrarMensaje('Producto guardado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al guardar: $e', Colors.redAccent);
    }
  }

  Future<void> _modificar() async {
    if (_selectedProdCodigo == null) {
      _mostrarMensaje('Seleccione un producto de la tabla para modificar', Colors.orange);
      return;
    }
    final descripcion = _descripcionController.text.trim();
    final precio = double.tryParse(_precioController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('productos')
          .update({
            'prod_nombre': descripcion.toUpperCase(),
            'prod_precio': precio,
            'prod_stock': stock,
            'idcategoria': _selectedCategoriaId,
            'prov_cod': _selectedProveedorId,
          })
          .eq('prod_codigo', _selectedProdCodigo!);

      _nuevo();
      _cargarDatos();
      _mostrarMensaje('Producto modificado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al modificar: $e', Colors.redAccent);
    }
  }

  Future<void> _eliminar() async {
    if (_selectedProdCodigo == null) {
      _mostrarMensaje('Seleccione un producto de la tabla para eliminar', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('productos')
          .delete()
          .eq('prod_codigo', _selectedProdCodigo!);

      _nuevo();
      _cargarDatos();
      _mostrarMensaje('Producto eliminado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al eliminar: $e', Colors.redAccent);
    }
  }

  void _buscar() {
    final filtro = _descripcionController.text.trim().toLowerCase();
    if (filtro.isEmpty) {
      _cargarDatos();
      return;
    }
    setState(() {
      _productos = _productos.where((prod) => 
        prod['prod_nombre'].toString().toLowerCase().contains(filtro) ||
        prod['prod_codigo'].toString().toLowerCase().contains(filtro)
      ).toList();
    });
  }

  void _nuevo() {
    _descripcionController.clear();
    _precioController.clear();
    _stockController.text = '0';
    setState(() {
      _selectedProdCodigo = null;
      if (_categorias.isNotEmpty) _selectedCategoriaId = _categorias[0]['idcategoria'];
      if (_proveedores.isNotEmpty) _selectedProveedorId = _proveedores[0]['prov_cod'];
    });
  }

  void _mostrarMensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mantenimiento de Productos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Descripción:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _descripcionController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Precio:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _precioController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Stock:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _stockController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Categoría', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedCategoriaId,
                                      dropdownColor: const Color(0xFF131A36),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration(),
                                      items: _categorias.map((cat) {
                                        return DropdownMenuItem(
                                          value: cat['idcategoria'].toString(),
                                          child: Text(cat['cat_nom'] ?? ''),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedCategoriaId = val),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Proveedor', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedProveedorId,
                                      dropdownColor: const Color(0xFF131A36),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration(),
                                      items: _proveedores.map((prov) {
                                        return DropdownMenuItem(
                                          value: prov['prov_cod'].toString(),
                                          child: Text(prov['razonsocial'] ?? ''),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedProveedorId = val),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A36),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.cyan.withOpacity(0.15)),
                                    dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.cyanAccent.withOpacity(0.3);
                                      }
                                      return null;
                                    }),
                                    columns: const [
                                      DataColumn(label: Text('Código', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Descripción', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Precio', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Stock', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Categoría', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Proveedor', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _productos.map((prod) {
                                      final isSelected = _selectedProdCodigo == prod['prod_codigo'];
                                      return DataRow(
                                        selected: isSelected,
                                        onSelectChanged: (selected) {
                                          setState(() {
                                            _selectedProdCodigo = prod['prod_codigo'];
                                            _descripcionController.text = prod['prod_nombre'] ?? '';
                                            _precioController.text = prod['prod_precio']?.toString() ?? '0';
                                            _stockController.text = prod['prod_stock']?.toString() ?? '0';
                                            if (_categorias.any((c) => c['idcategoria'] == prod['idcategoria'])) {
                                              _selectedCategoriaId = prod['idcategoria'];
                                            }
                                            if (_proveedores.any((p) => p['prov_cod'] == prod['prov_cod'])) {
                                              _selectedProveedorId = prod['prov_cod'];
                                            }
                                          });
                                        },
                                        cells: [
                                          DataCell(Text(prod['prod_codigo'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prod['prod_nombre'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prod['prod_precio']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prod['prod_stock']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prod['idcategoria'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prod['prov_cod'] ?? '', style: const TextStyle(color: Colors.white))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 130,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton('Nuevo', Colors.white, const Color(0xFF1F294D), _nuevo),
                  const SizedBox(height: 12),
                  _buildActionButton('Grabar', Colors.cyanAccent, const Color(0xFF0A0E21), _grabar),
                  const SizedBox(height: 12),
                  _buildActionButton('Buscar', Colors.white, const Color(0xFF1F294D), _buscar),
                  const SizedBox(height: 12),
                  _buildActionButton('Modificar', Colors.white, const Color(0xFF1F294D), _modificar),
                  const SizedBox(height: 12),
                  _buildActionButton('Eliminar', Colors.redAccent, const Color(0xFF1F294D), _eliminar),
                  const SizedBox(height: 12),
                  _buildActionButton('Salir', Colors.white, const Color(0xFF1F294D), () => Navigator.pop(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.cyanAccent),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildActionButton(String texto, Color textColor, Color bgColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          side: BorderSide(color: Colors.cyan.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          texto,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}