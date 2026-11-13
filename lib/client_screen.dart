import 'package:flutter/material.dart';
import 'main.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _rucController = TextEditingController();
  
  String _selectedDistrito = 'ATE';
  final List<String> _distritos = ['ATE', 'SANTA ANITA', 'LA VICTORIA', 'JESUS MARIA', 'SAN ISIDRO', 'COMAS', 'SAN LUIS'];

  List<dynamic> _clientes = [];
  bool _isLoading = false;
  String? _selectedCliCodigo;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('clientes')
          .select()
          .order('cli_codigo', ascending: true);
      
      setState(() {
        _clientes = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar clientes: $e', Colors.redAccent);
    }
  }

  Future<void> _grabar() async {
    final nombre = _nombreController.text.trim();
    final dni = _dniController.text.trim();
    final direccion = _direccionController.text.trim();
    final telefono = _telefonoController.text.trim();
    final ruc = _rucController.text.trim();

    if (nombre.isEmpty || dni.isEmpty) {
      _mostrarMensaje('Ingrese al menos Nombre y DNI', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resMax = await supabase
          .from('clientes')
          .select('cli_codigo')
          .order('cli_codigo', ascending: false)
          .limit(1);

      String nuevoCodigo = 'C0001';
      if ((resMax as List).isNotEmpty) {
        String ultimoCod = resMax[0]['cli_codigo'].toString();
        int num = int.parse(ultimoCod.substring(1)) + 1;
        nuevoCodigo = 'C${num.toString().padLeft(4, '0')}';
      }

      await supabase.from('clientes').insert({
        'cli_codigo': nuevoCodigo,
        'cli_dni': dni,
        'cli_nombre': nombre.toUpperCase(),
        'cli_telefono': telefono,
        'cli_ruc': ruc,
        'cli_direccion': direccion.toUpperCase(),
        'cli_dist': _selectedDistrito,
      });

      _nuevo();
      _cargarClientes();
      _mostrarMensaje('Cliente guardado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al guardar: $e', Colors.redAccent);
    }
  }

  Future<void> _modificar() async {
    if (_selectedCliCodigo == null) {
      _mostrarMensaje('Seleccione un cliente de la tabla para modificar', Colors.orange);
      return;
    }
    final nombre = _nombreController.text.trim();
    final dni = _dniController.text.trim();
    final direccion = _direccionController.text.trim();
    final telefono = _telefonoController.text.trim();
    final ruc = _rucController.text.trim();

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('clientes')
          .update({
            'cli_dni': dni,
            'cli_nombre': nombre.toUpperCase(),
            'cli_telefono': telefono,
            'cli_ruc': ruc,
            'cli_direccion': direccion.toUpperCase(),
            'cli_dist': _selectedDistrito,
          })
          .eq('cli_codigo', _selectedCliCodigo!);

      _nuevo();
      _cargarClientes();
      _mostrarMensaje('Cliente modificado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al modificar: $e', Colors.redAccent);
    }
  }

  Future<void> _eliminar() async {
    if (_selectedCliCodigo == null) {
      _mostrarMensaje('Seleccione un cliente de la tabla para eliminar', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('clientes')
          .delete()
          .eq('cli_codigo', _selectedCliCodigo!);

      _nuevo();
      _cargarClientes();
      _mostrarMensaje('Cliente eliminado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('No se puede eliminar (puede tener transacciones asociadas)', Colors.redAccent);
    }
  }

  void _buscar() {
    final filtro = _nombreController.text.trim().toLowerCase();
    final dniFiltro = _dniController.text.trim().toLowerCase();
    if (filtro.isEmpty && dniFiltro.isEmpty) {
      _cargarClientes();
      return;
    }
    setState(() {
      _clientes = _clientes.where((cli) => 
        cli['cli_nombre'].toString().toLowerCase().contains(filtro) ||
        cli['cli_dni'].toString().toLowerCase().contains(dniFiltro) ||
        cli['cli_codigo'].toString().toLowerCase().contains(filtro)
      ).toList();
    });
  }

  void _nuevo() {
    _nombreController.clear();
    _dniController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    _rucController.clear();
    setState(() {
      _selectedCliCodigo = null;
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
        title: const Text('Mantenimiento de Clientes', style: TextStyle(color: Colors.white)),
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
                          'Datos del Cliente',
                          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text('Apellidos y Nombre(s):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _nombreController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DNI:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _dniController,
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
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
                            const SizedBox(width: 12),
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
                                      DataColumn(label: Text('DNI', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Nombre', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Teléfono', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('RUC', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Dirección', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Distrito', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _clientes.map((cli) {
                                      final isSelected = _selectedCliCodigo == cli['cli_codigo'];
                                      return DataRow(
                                        selected: isSelected,
                                        onSelectChanged: (selected) {
                                          setState(() {
                                            _selectedCliCodigo = cli['cli_codigo'];
                                            _nombreController.text = cli['cli_nombre'] ?? '';
                                            _dniController.text = cli['cli_dni'] ?? '';
                                            _direccionController.text = cli['cli_direccion'] ?? '';
                                            _telefonoController.text = cli['cli_telefono'] ?? '';
                                            _rucController.text = cli['cli_ruc'] ?? '';
                                            if (_distritos.contains(cli['cli_dist'])) {
                                              _selectedDistrito = cli['cli_dist'];
                                            }
                                          });
                                        },
                                        cells: [
                                          DataCell(Text(cli['cli_codigo'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(cli['cli_dni'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(cli['cli_nombre'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(cli['cli_telefono'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(cli['cli_ruc'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(cli['cli_direccion'] ?? '', style: const TextStyle(color: Colors.white))),
                                          DataCell(Text(cli['cli_dist'] ?? '', style: const TextStyle(color: Colors.white))),
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