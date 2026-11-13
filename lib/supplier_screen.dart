import 'package:flutter/material.dart';
import 'main.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final _razonSocialController = TextEditingController();
  final _rucController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedDistrito = 'ATE';
  final List<String> _distritos = ['ATE', 'SANTA ANITA', 'LA VICTORIA', 'JESUS MARIA', 'SAN ISIDRO', 'COMAS', 'SAN LUIS'];

  List<dynamic> _proveedores = [];
  bool _isLoading = false;
  String? _selectedProvCodigo;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('proveedores')
          .select()
          .order('prov_cod', ascending: true);
      
      setState(() {
        _proveedores = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar proveedores: $e', Colors.redAccent);
    }
  }

  Future<void> _grabar() async {
    final razonSocial = _razonSocialController.text.trim();
    final ruc = _rucController.text.trim();
    final direccion = _direccionController.text.trim();
    final telefono = _telefonoController.text.trim();
    final celular = _celularController.text.trim();
    final email = _emailController.text.trim();

    if (razonSocial.isEmpty || ruc.isEmpty) {
      _mostrarMensaje('Ingrese al menos Razón Social y R.U.C.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resMax = await supabase
          .from('proveedores')
          .select('prov_cod')
          .order('prov_cod', ascending: false)
          .limit(1);

      String nuevoCodigo = 'P0001';
      if ((resMax as List).isNotEmpty) {
        String ultimoCod = resMax[0]['prov_cod'].toString();
        int num = int.parse(ultimoCod.substring(1)) + 1;
        nuevoCodigo = 'P${num.toString().padLeft(4, '0')}';
      }

      await supabase.from('proveedores').insert({
        'prov_cod': nuevoCodigo,
        'razonsocial': razonSocial.toUpperCase(),
        'ruc': ruc,
        'prov_direc': direccion.toUpperCase(),
        'prov_dist': _selectedDistrito,
        'prov_telefono': telefono,
        'prov_celular': celular,
        'prov_mail': email,
      });

      _nuevo();
      _cargarProveedores();
      _mostrarMensaje('Proveedor guardado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al guardar: $e', Colors.redAccent);
    }
  }

  Future<void> _modificar() async {
    if (_selectedProvCodigo == null) {
      _mostrarMensaje('Seleccione un proveedor de la tabla para modificar', Colors.orange);
      return;
    }
    final razonSocial = _razonSocialController.text.trim();
    final ruc = _rucController.text.trim();
    final direccion = _direccionController.text.trim();
    final telefono = _telefonoController.text.trim();
    final celular = _celularController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('proveedores')
          .update({
            'razonsocial': razonSocial.toUpperCase(),
            'ruc': ruc,
            'prov_direc': direccion.toUpperCase(),
            'prov_dist': _selectedDistrito,
            'prov_telefono': telefono,
            'prov_celular': celular,
            'prov_mail': email,
          })
          .eq('prov_cod', _selectedProvCodigo!);

      _nuevo();
      _cargarProveedores();
      _mostrarMensaje('Proveedor modificado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al modificar: $e', Colors.redAccent);
    }
  }

  Future<void> _eliminar() async {
    if (_selectedProvCodigo == null) {
      _mostrarMensaje('Seleccione un proveedor de la tabla para eliminar', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('proveedores')
          .delete()
          .eq('prov_cod', _selectedProvCodigo!);

      _nuevo();
      _cargarProveedores();
      _mostrarMensaje('Proveedor eliminado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('No se puede eliminar (puede tener productos asociados)', Colors.redAccent);
    }
  }

  void _buscar() {
    final filtro = _razonSocialController.text.trim().toLowerCase();
    final rucFiltro = _rucController.text.trim().toLowerCase();
    if (filtro.isEmpty && rucFiltro.isEmpty) {
      _cargarProveedores();
      return;
    }
    setState(() {
      _proveedores = _proveedores.where((prov) => 
        prov['razonsocial'].toString().toLowerCase().contains(filtro) ||
        prov['ruc'].toString().toLowerCase().contains(rucFiltro) ||
        prov['prov_cod'].toString().toLowerCase().contains(filtro)
      ).toList();
    });
  }

  void _nuevo() {
    _razonSocialController.clear();
    _rucController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    _celularController.clear();
    _emailController.clear();
    setState(() {
      _selectedProvCodigo = null;
      _selectedDistrito = 'ATE';
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
        title: const Text('Mantenimiento de Proveedores', style: TextStyle(color: Colors.white)),
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
                        const Text(
                          'Datos de Proveedor',
                          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Razón Social:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _razonSocialController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('R.U.C.:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _rucController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dirección:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _direccionController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Distrito:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    value: _selectedDistrito,
                                    dropdownColor: const Color(0xFF131A36),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                    items: _distritos.map((dist) {
                                      return DropdownMenuItem(value: dist, child: Text(dist));
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedDistrito = val!);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Teléfono:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _telefonoController,
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
                                  const Text('Celular:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _celularController,
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
                                  const Text('E-mail:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
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
                                      DataColumn(label: Text('RazonSocial', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('RUC', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('E-mail', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Telefono', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Celular', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Dirección', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Distrito', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _proveedores.map((prov) {
                                      final isSelected = _selectedProvCodigo == prov['prov_cod'];
                                      return DataRow(
                                        selected: isSelected,
                                        onSelectChanged: (selected) {
                                          setState(() {
                                            _selectedProvCodigo = prov['prov_cod'];
                                            _razonSocialController.text = prov['razonsocial'] ?? '';
                                            _rucController.text = prov['ruc'] ?? '';
                                            _direccionController.text = prov['prov_direc'] ?? '';
                                            _telefonoController.text = prov['prov_telefono'] ?? '';
                                            _celularController.text = prov['prov_celular'] ?? '';
                                            _emailController.text = prov['prov_mail'] ?? '';
                                            if (_distritos.contains(prov['prov_dist'])) {
                                              _selectedDistrito = prov['prov_dist'];
                                            }
                                          });
                                        },
                                        cells: [
                                          DataCell(Text(prov['prov_cod'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prov['razonsocial'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prov['ruc'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prov['prov_mail'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prov['prov_telefono'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prov['prov_celular'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prov['prov_direc'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(prov['prov_dist'] ?? '', style: const TextStyle(color: Colors.white))),
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