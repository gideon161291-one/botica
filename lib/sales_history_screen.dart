import 'package:flutter/material.dart';
import 'main.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _todasLasVentas = [];
  List<dynamic> _ventasFiltradas = [];

  // Filtros inicializados por defecto para evitar errores de valor nulo en los Dropdown
  String _tipoSeleccionado = 'TODOS'; // 'TODOS', 'BOLETA', 'FACTURA'
  String _usuarioSeleccionado = 'TODOS';
  DateTime? _fechaSeleccionada;
  List<String> _usuariosDisponibles = [];

  double _montoTotalFiltrado = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarHistorialVentas();
  }

  Future<void> _cargarHistorialVentas() async {
    setState(() => _isLoading = true);
    try {
      // 1. Consultar boletas, facturas y clientes simultáneamente desde Supabase
      final resBoletas = await supabase.from('boletas').select();
      final resFacturas = await supabase.from('facturas').select();
      final resClientes = await supabase.from('clientes').select();

      // Crear un mapa para relacionar el código del cliente con su nombre
      Map<String, String> clientesMap = {};
      for (var c in (resClientes as List)) {
        String codigo = c['cli_codigo']?.toString() ?? '';
        String nombre = c['cli_nombre']?.toString() ?? 'S/N';
        if (codigo.isNotEmpty) {
          clientesMap[codigo] = nombre;
        }
      }

      List<dynamic> listaBoletas = (resBoletas as List).map((b) {
        String codCli = b['cli_codigo']?.toString() ?? '';
        String nombreCliente = clientesMap[codCli] ?? codCli;

        return {
          'tipo': 'BOLETA',
          'nro': b['nro_boleta'] ?? '',
          'cliente': nombreCliente,
          'total': double.tryParse(b['total'].toString()) ?? 0.0,
          'usuario': b['usu_codigo']?.toString().toUpperCase() ?? 'GENERAL',
          'fecha': b['fecha']?.toString() ?? b['created_at']?.toString() ?? '',
        };
      }).toList();

      List<dynamic> listaFacturas = (resFacturas as List).map((f) {
        String codCli = f['cli_codigo']?.toString() ?? '';
        String nombreCliente = clientesMap[codCli] ?? codCli;

        return {
          'tipo': 'FACTURA',
          'nro': f['nro_factura'] ?? '',
          'cliente': nombreCliente,
          'total': double.tryParse(f['total'].toString()) ?? 0.0,
          'usuario': f['usu_codigo']?.toString().toUpperCase() ?? 'GENERAL',
          'fecha': f['fecha']?.toString() ?? f['created_at']?.toString() ?? '',
        };
      }).toList();

      // 2. Unir ambas listas de comprobantes
      List<dynamic> unificadas = [...listaBoletas, ...listaFacturas];

      // 3. ORDENAR CRONOLÓGICAMENTE Y POR NÚMERO (Doble criterio)
      unificadas.sort((a, b) {
        int cmpFecha = b['fecha'].compareTo(a['fecha']);
        if (cmpFecha != 0) return cmpFecha;
        // Si tienen la misma fecha, ordena por el número de comprobante de forma descendente
        return b['nro'].compareTo(a['nro']);
      });

      // Extraer usuarios únicos para el filtro
      Set<String> usuariosSet = unificadas.map((e) => e['usuario'].toString()).toSet();

      setState(() {
        _todasLasVentas = unificadas;
        _ventasFiltradas = unificadas;
        _usuariosDisponibles = usuariosSet.toList();
        _isLoading = false;
      });

      _aplicarFiltros();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar historial: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _aplicarFiltros() {
    List<dynamic> temp = List.from(_todasLasVentas);

    // Filtro por Tipo de Comprobante
    if (_tipoSeleccionado != 'TODOS') {
      temp = temp.where((v) => v['tipo'] == _tipoSeleccionado).toList();
    }

    // Filtro por Usuario
    if (_usuarioSeleccionado != 'TODOS') {
      temp = temp.where((v) => v['usuario'] == _usuarioSeleccionado).toList();
    }

    // Filtro por Fecha
    if (_fechaSeleccionada != null) {
      String fechaFiltroStr = _fechaSeleccionada!.toIso8601String().split('T')[0];
      temp = temp.where((v) {
        String fechaVenta = v['fecha'];
        return fechaVenta.startsWith(fechaFiltroStr);
      }).toList();
    }

    // Calcular monto total filtrado
    double totalSuma = 0.0;
    for (var v in temp) {
      totalSuma += v['total'];
    }

    setState(() {
      _ventasFiltradas = temp;
      _montoTotalFiltrado = totalSuma;
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _usuarioSeleccionado = 'TODOS';
      _tipoSeleccionado = 'TODOS';
      _fechaSeleccionada = null;
    });
    _aplicarFiltros();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Color(0xFF0A0E21),
              surface: Color(0xFF131A36),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      _aplicarFiltros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Historial y Reporte de Ventas', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel de Filtros
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Filtro Tipo
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            value: _tipoSeleccionado,
                            dropdownColor: const Color(0xFF131A36),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Comprobante'),
                            items: const [
                              DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
                              DropdownMenuItem(value: 'BOLETA', child: Text('Boletas')),
                              DropdownMenuItem(value: 'FACTURA', child: Text('Facturas')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _tipoSeleccionado = val);
                                _aplicarFiltros();
                              }
                            },
                          ),
                        ),
                        // Filtro Usuario
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            value: _usuarioSeleccionado,
                            dropdownColor: const Color(0xFF131A36),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Usuario'),
                            items: [
                              const DropdownMenuItem(value: 'TODOS', child: Text('Todos los usuarios')),
                              ..._usuariosDisponibles.map((u) => DropdownMenuItem(value: u, child: Text(u))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _usuarioSeleccionado = val);
                                _aplicarFiltros();
                              }
                            },
                          ),
                        ),
                        // Selector de Fecha
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F294D),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _seleccionarFecha(context),
                          icon: const Icon(Icons.calendar_today, color: Colors.cyanAccent, size: 18),
                          label: Text(
                            _fechaSeleccionada == null 
                                ? 'Filtrar Fecha' 
                                : _fechaSeleccionada!.toLocal().toString().split(' ')[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        // Botón Limpiar
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.cyan.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _limpiarFiltros,
                          child: const Text('Limpiar', style: TextStyle(color: Colors.cyanAccent)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tarjetas de Resumen
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A36),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Comprobantes Filtrados', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('${_ventasFiltradas.length}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A36),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyanAccent, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monto Total Recaudado', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('S/. ${_montoTotalFiltrado.toStringAsFixed(2)}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tabla de Resultados
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A36),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.cyan.withOpacity(0.15)),
                              columns: const [
                                DataColumn(label: Text('Tipo', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Nro. Comprobante', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Cliente', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Cajero', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Fecha', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Total (S/.)', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                              ],
                              rows: _ventasFiltradas.map((v) {
                                bool esFactura = v['tipo'] == 'FACTURA';
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: esFactura ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: esFactura ? Colors.purpleAccent : Colors.cyanAccent),
                                        ),
                                        child: Text(
                                          v['tipo'],
                                          style: TextStyle(
                                            color: esFactura ? Colors.purpleAccent : Colors.cyanAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(v['nro'], style: const TextStyle(color: Colors.white))),
                                    DataCell(Text(v['cliente'], style: const TextStyle(color: Colors.white70))),
                                    DataCell(Text(v['usuario'], style: const TextStyle(color: Colors.white70))),
                                    DataCell(Text(v['fecha'].toString().split('T')[0], style: const TextStyle(color: Colors.white70))),
                                    DataCell(Text('S/. ${v['total'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
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
}