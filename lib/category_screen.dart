import 'package:flutter/material.dart';
import 'main.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _nombreController = TextEditingController();
  List<dynamic> _categorias = [];
  bool _isLoading = false;
  String? _selectedIdCategoria;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('categoria')
          .select()
          .order('idcategoria', ascending: true);
      
      setState(() {
        _categorias = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar categorías: $e', Colors.redAccent);
    }
  }

  Future<void> _grabar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      _mostrarMensaje('Ingrese el nombre de la categoría', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resMax = await supabase
          .from('categoria')
          .select('idcategoria')
          .order('idcategoria', ascending: false)
          .limit(1);

      String nuevoCodigo = 'C0001';
      if ((resMax as List).isNotEmpty) {
        String ultimoCod = resMax[0]['idcategoria'].toString();
        int num = int.parse(ultimoCod.substring(1)) + 1;
        nuevoCodigo = 'C${num.toString().padLeft(4, '0')}';
      }

      await supabase.from('categoria').insert({
        'idcategoria': nuevoCodigo,
        'cat_nom': nombre.toUpperCase(),
      });

      _nuevo();
      _cargarCategorias();
      _mostrarMensaje('Categoría guardada con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al guardar: $e', Colors.redAccent);
    }
  }

  Future<void> _modificar() async {
    if (_selectedIdCategoria == null) {
      _mostrarMensaje('Seleccione una categoría de la tabla para modificar', Colors.orange);
      return;
    }
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      _mostrarMensaje('El nombre no puede estar vacío', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('categoria')
          .update({'cat_nom': nombre.toUpperCase()})
          .eq('idcategoria', _selectedIdCategoria!);

      _nuevo();
      _cargarCategorias();
      _mostrarMensaje('Categoría modificada con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al modificar: $e', Colors.redAccent);
    }
  }

  Future<void> _eliminar() async {
    if (_selectedIdCategoria == null) {
      _mostrarMensaje('Seleccione una categoría de la tabla para eliminar', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('categoria')
          .delete()
          .eq('idcategoria', _selectedIdCategoria!);

      _nuevo();
      _cargarCategorias();
      _mostrarMensaje('Categoría eliminada con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('No se puede eliminar (puede estar en uso por productos)', Colors.redAccent);
    }
  }

  void _buscar() {
    final filtro = _nombreController.text.trim().toLowerCase();
    if (filtro.isEmpty) {
      _cargarCategorias();
      return;
    }
    setState(() {
      _categorias = _categorias.where((cat) => 
        cat['cat_nom'].toString().toLowerCase().contains(filtro) ||
        cat['idcategoria'].toString().toLowerCase().contains(filtro)
      ).toList();
    });
  }

  void _nuevo() {
    _nombreController.clear();
    setState(() {
      _selectedIdCategoria = null;
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
        title: const Text('Mantenimiento de Categorías', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
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
                        const Text(
                          'Datos de la Categoría',
                          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Nombre:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _nombreController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
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
                              child: ListView(
                                children: [
                                  DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.cyan.withOpacity(0.15)),
                                    dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.cyanAccent.withOpacity(0.3);
                                      }
                                      return null;
                                    }),
                                    columns: const [
                                      DataColumn(label: Text('Código', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Nombre', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _categorias.map((cat) {
                                      final isSelected = _selectedIdCategoria == cat['idcategoria'];
                                      return DataRow(
                                        selected: isSelected,
                                        onSelectChanged: (selected) {
                                          setState(() {
                                            _selectedIdCategoria = cat['idcategoria'];
                                            _nombreController.text = cat['cat_nom'] ?? '';
                                          });
                                        },
                                        cells: [
                                          DataCell(Text(cat['idcategoria'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(cat['cat_nom'] ?? '', style: const TextStyle(color: Colors.white))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _nuevo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Nuevo'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Salir'),
                      ),
                    ],
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
                  _buildActionButton('Grabar', Colors.cyanAccent, const Color(0xFF0A0E21), _grabar),
                  const SizedBox(height: 12),
                  _buildActionButton('Buscar', Colors.white, const Color(0xFF1F294D), _buscar),
                  const SizedBox(height: 12),
                  _buildActionButton('Modificar', Colors.white, const Color(0xFF1F294D), _modificar),
                  const SizedBox(height: 12),
                  _buildActionButton('Eliminar', Colors.redAccent, const Color(0xFF1F294D), _eliminar),
                ],
              ),
            ),
          ],
        ),
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