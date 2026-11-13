import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'main.dart';

class SaleScreen extends StatefulWidget {
  final String usuarioActual;

  const SaleScreen({super.key, this.usuarioActual = 'GIAN'});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _clienteController = TextEditingController();
  final _direccionController = TextEditingController();
  final _documentoController = TextEditingController();

  List<dynamic> _detallesVenta = [];
  List<dynamic> _productosDisponibles = [];
  List<dynamic> _clientesDisponibles = [];

  bool _isLoading = false;
  String _tipoComprobante = 'BOLETA'; // 'BOLETA' o 'FACTURA'
  String _numeroComprobante = '001-000001';
  String? _selectedCliCodigo;
  Map<String, dynamic>? _clienteSeleccionadoMap;

  double _subtotalGeneral = 0.0;
  double _igvGeneral = 0.0;
  double _totalGeneral = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    try {
      final resProd = await supabase.from('productos').select();
      final resCli = await supabase.from('clientes').select();

      await _actualizarCorrelativo();

      setState(() {
        _productosDisponibles = (resProd as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
        _clientesDisponibles = (resCli as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar datos: $e', Colors.redAccent);
    }
  }

  Future<void> _actualizarCorrelativo() async {
    if (_tipoComprobante == 'BOLETA') {
      final resMax = await supabase.from('boletas').select('nro_boleta').order('idboleta', ascending: false).limit(1);
      if ((resMax as List).isNotEmpty) {
        String ultimoNro = resMax[0]['nro_boleta'].toString();
        int num = int.parse(ultimoNro.split('-').last) + 1;
        setState(() {
          _numeroComprobante = '001-${num.toString().padLeft(6, '0')}';
        });
      } else {
        setState(() {
          _numeroComprobante = '001-000001';
        });
      }
    } else {
      final resMax = await supabase.from('facturas').select('nro_factura').order('idfactura', ascending: false).limit(1);
      if ((resMax as List).isNotEmpty) {
        String ultimoNro = resMax[0]['nro_factura'].toString();
        int num = int.parse(ultimoNro.split('-').last) + 1;
        setState(() {
          _numeroComprobante = 'F001-${num.toString().padLeft(6, '0')}';
        });
      } else {
        setState(() {
          _numeroComprobante = 'F001-000001';
        });
      }
    }
  }

  void _actualizarDocumentoCliente() {
    if (_clienteSeleccionadoMap == null) return;
    final cli = _clienteSeleccionadoMap!;
    final String ruc = cli['cli_ruc']?.toString().trim() ?? '';
    final String dni = cli['cli_dni']?.toString().trim() ?? '';

    if (_tipoComprobante == 'FACTURA') {
      _documentoController.text = ruc.isNotEmpty ? ruc : dni;
    } else {
      _documentoController.text = dni.isNotEmpty ? dni : ruc;
    }
  }

  void _buscarClienteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131A36),
          title: const Text('Buscar Cliente', style: TextStyle(color: Colors.cyanAccent)),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: _clientesDisponibles.length,
              itemBuilder: (context, index) {
                final cli = _clientesDisponibles[index];
                final String ruc = cli['cli_ruc']?.toString().trim() ?? '';
                final String dni = cli['cli_dni']?.toString().trim() ?? '';
                final String infoDoc = [
                  if (dni.isNotEmpty) 'DNI: $dni',
                  if (ruc.isNotEmpty) 'RUC: $ruc',
                ].join(' | ');

                return ListTile(
                  title: Text(cli['cli_nombre'] ?? '', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${infoDoc.isNotEmpty ? infoDoc : 'Sin documento'}\n${cli['cli_direccion'] ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    setState(() {
                      _clienteSeleccionadoMap = cli;
                      _selectedCliCodigo = cli['cli_codigo'];
                      _clienteController.text = cli['cli_nombre'] ?? '';
                      _direccionController.text = cli['cli_direccion'] ?? '';
                      _actualizarDocumentoCliente();
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _agregarProductoDialog() {
    String? selectedProdCodigo;
    final cantidadController = TextEditingController(text: '1');

    if (_productosDisponibles.isNotEmpty) {
      selectedProdCodigo = _productosDisponibles[0]['prod_codigo'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131A36),
          title: const Text('Añadir Producto', style: TextStyle(color: Colors.cyanAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedProdCodigo,
                dropdownColor: const Color(0xFF131A36),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(),
                items: _productosDisponibles.map((p) {
                  return DropdownMenuItem(
                    value: p['prod_codigo'].toString(),
                    child: Text('${p['prod_nombre']} (Stock: ${p['prod_stock']} - S/. ${p['prod_precio']})'),
                  );
                }).toList(),
                onChanged: (val) => selectedProdCodigo = val,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration().copyWith(labelText: 'Cantidad'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () {
                final prod = _productosDisponibles.firstWhere((p) => p['prod_codigo'] == selectedProdCodigo);
                final int cantidad = int.tryParse(cantidadController.text) ?? 1;
                final double precio = double.tryParse(prod['prod_precio'].toString()) ?? 0.0;
                final int stockActual = int.tryParse(prod['prod_stock'].toString()) ?? 0;

                if (cantidad <= 0) {
                  _mostrarMensaje('La cantidad debe ser mayor a 0', Colors.orange);
                  return;
                }

                if (cantidad > stockActual) {
                  _mostrarMensaje('Stock insuficiente (Disponible: $stockActual)', Colors.orange);
                  return;
                }

                final double subtotal = precio * cantidad;

                setState(() {
                  _detallesVenta.add({
                    'codigo': prod['prod_codigo'],
                    'descripcion': prod['prod_nombre'],
                    'precio': precio,
                    'cantidad': cantidad,
                    'subtotal': subtotal,
                  });
                  _calcularTotales();
                });
                Navigator.pop(context);
              },
              child: const Text('Añadir', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _quitarProducto() {
    if (_detallesVenta.isNotEmpty) {
      setState(() {
        _detallesVenta.removeLast();
        _calcularTotales();
      });
    }
  }

  void _calcularTotales() {
    double sumaSubtotales = 0.0;
    for (var item in _detallesVenta) {
      sumaSubtotales += item['subtotal'];
    }

    if (_tipoComprobante == 'FACTURA') {
      _totalGeneral = sumaSubtotales;
      _subtotalGeneral = _totalGeneral / 1.18;
      _igvGeneral = _totalGeneral - _subtotalGeneral;
    } else {
      _subtotalGeneral = sumaSubtotales;
      _igvGeneral = 0.0;
      _totalGeneral = sumaSubtotales;
    }
  }

  void _nuevo() {
    _clienteController.clear();
    _direccionController.clear();
    _documentoController.clear();
    setState(() {
      _clienteSeleccionadoMap = null;
      _selectedCliCodigo = null;
      _detallesVenta.clear();
      _subtotalGeneral = 0.0;
      _igvGeneral = 0.0;
      _totalGeneral = 0.0;
      _cargarDatosIniciales();
    });
  }

  Future<void> _grabar() async {
    if (_selectedCliCodigo == null || _detallesVenta.isEmpty) {
      _mostrarMensaje('Seleccione un cliente y añada al menos un producto', Colors.orange);
      return;
    }

    if (_tipoComprobante == 'FACTURA' && _documentoController.text.trim().length != 11) {
      _mostrarMensaje('La Factura requiere un cliente con RUC válido de 11 dígitos', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_tipoComprobante == 'BOLETA') {
        await supabase.from('boletas').insert({
          'nro_boleta': _numeroComprobante,
          'cli_codigo': _selectedCliCodigo,
          'total': _totalGeneral,
          'usu_codigo': widget.usuarioActual,
        });

        for (var item in _detallesVenta) {
          await supabase.from('detalle_boleta').insert({
            'nro_boleta': _numeroComprobante,
            'prod_codigo': item['codigo'],
            'cantidad': item['cantidad'],
            'precio': item['precio'],
            'subtotal': item['subtotal'],
          });
          await _actualizarStockProducto(item['codigo'], item['cantidad']);
        }
      } else {
        await supabase.from('facturas').insert({
          'nro_factura': _numeroComprobante,
          'cli_codigo': _selectedCliCodigo,
          'subtotal': _subtotalGeneral,
          'igv': _igvGeneral,
          'total': _totalGeneral,
          'usu_codigo': widget.usuarioActual,
        });

        for (var item in _detallesVenta) {
          await supabase.from('detalle_factura').insert({
            'nro_factura': _numeroComprobante,
            'prod_codigo': item['codigo'],
            'cantidad': item['cantidad'],
            'precio': item['precio'],
            'subtotal': item['subtotal'],
          });
          await _actualizarStockProducto(item['codigo'], item['cantidad']);
        }
      }

      setState(() => _isLoading = false);
      _mostrarMensaje('¡$_tipoComprobante registrada y stock actualizado con éxito!', Colors.green);

      await _imprimirTicket();
      _nuevo();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al registrar comprobante: $e', Colors.redAccent);
    }
  }

  Future<void> _actualizarStockProducto(String prodCodigo, int cantidadVendida) async {
    final resProd = await supabase
        .from('productos')
        .select('prod_stock')
        .eq('prod_codigo', prodCodigo)
        .single();

    int stockActual = int.tryParse(resProd['prod_stock'].toString()) ?? 0;
    int nuevoStock = stockActual - cantidadVendida;
    if (nuevoStock < 0) nuevoStock = 0;

    await supabase
        .from('productos')
        .update({'prod_stock': nuevoStock})
        .eq('prod_codigo', prodCodigo);
  }

  Future<pw.Document> _generarPdfTicket() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final fechaActual = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('SISTEMA CYBERPUNK S.A.C.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text('R.U.C.: 16458745841', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Center(
                child: pw.Text('Av. Tecnológica 1020 - Lima', style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Center(
                child: pw.Text(
                  _tipoComprobante == 'BOLETA' ? 'BOLETA DE VENTA ELECTRÓNICA' : 'FACTURA ELECTRÓNICA',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ),
              pw.Center(
                child: pw.Text(_numeroComprobante, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Fecha: $fechaActual', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Cajero: ${widget.usuarioActual}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Cliente: ${_clienteController.text}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('${_tipoComprobante == 'BOLETA' ? 'DNI' : 'RUC'}: ${_documentoController.text}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Dirección: ${_direccionController.text}', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cant. Descripción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text('P.Unit  Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              ..._detallesVenta.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item['descripcion'], style: const pw.TextStyle(fontSize: 9)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('  ${item['cantidad']} x ${item['precio'].toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('S/. ${item['subtotal'].toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              if (_tipoComprobante == 'FACTURA') ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SUBTOTAL:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('S/. ${_subtotalGeneral.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('I.G.V. (18%):', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('S/. ${_igvGeneral.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL A PAGAR:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('S/. ${_totalGeneral.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Center(
                child: pw.Text('¡Representación impresa Electrónica!', style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Center(
                child: pw.Text('Gracias por su preferencia', style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _imprimirTicket() async {
    if (_detallesVenta.isEmpty) {
      _mostrarMensaje('No hay productos para imprimir', Colors.orange);
      return;
    }
    final pdfData = await _generarPdfTicket();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData.save(),
    );
  }

  void _mostrarMensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fechaActual = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Emisión de Comprobantes (${widget.usuarioActual})', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector de Tipo de Comprobante
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A36),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tipo de Comprobante:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: _tipoComprobante,
                                dropdownColor: const Color(0xFF131A36),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                items: const [
                                  DropdownMenuItem(value: 'BOLETA', child: Text('Boleta de Venta')),
                                  DropdownMenuItem(value: 'FACTURA', child: Text('Factura Electrónica')),
                                ],
                                onChanged: (val) async {
                                  setState(() {
                                    _tipoComprobante = val!;
                                    _actualizarDocumentoCliente();
                                    _calcularTotales();
                                  });
                                  await _actualizarCorrelativo();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(14),
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
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Cliente:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                              const SizedBox(height: 3),
                                              TextField(
                                                controller: _clienteController,
                                                readOnly: true,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: _inputDecoration(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 18.0),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F294D)),
                                            onPressed: _buscarClienteDialog,
                                            child: const Text('Buscar...', style: TextStyle(color: Colors.cyanAccent)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Dirección:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                              const SizedBox(height: 3),
                                              TextField(
                                                controller: _direccionController,
                                                readOnly: true,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: _inputDecoration(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_tipoComprobante == 'BOLETA' ? 'DNI:' : 'RUC:', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                              const SizedBox(height: 3),
                                              TextField(
                                                controller: _documentoController,
                                                readOnly: true,
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131A36),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.cyanAccent, width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(_tipoComprobante, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    const Text('R.U.C.: 16458745841', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('Nro.: $_numeroComprobante', style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 8),
                                    Text('Fecha: $fechaActual', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131A36),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(Colors.cyan.withOpacity(0.15)),
                                        columns: const [
                                          DataColumn(label: Text('Codigo', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Descripcion', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Precio', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Cantidad', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Subtotal', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                        ],
                                        rows: _detallesVenta.map((item) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(item['codigo'], style: const TextStyle(color: Colors.white))),
                                              DataCell(Text(item['descripcion'], style: const TextStyle(color: Colors.white))),
                                              DataCell(Text(item['precio'].toStringAsFixed(2), style: const TextStyle(color: Colors.white))),
                                              DataCell(Text(item['cantidad'].toString(), style: const TextStyle(color: Colors.white))),
                                              DataCell(Text(item['subtotal'].toStringAsFixed(2), style: const TextStyle(color: Colors.white))),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                                  onPressed: _agregarProductoDialog,
                                  child: const Text('Añadir', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: _quitarProducto,
                                  child: const Text('Quitar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_tipoComprobante == 'FACTURA') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Subtotal S/. ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              SizedBox(
                                width: 150,
                                child: Text(_subtotalGeneral.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('IGV (18%) S/. ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              SizedBox(
                                width: 150,
                                child: Text(_igvGeneral.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Total S/. ', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                border: Border.all(color: Colors.cyanAccent),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _totalGeneral.toStringAsFixed(2),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.right,
                              ),
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildActionButton('Nuevo', Colors.white, const Color(0xFF1F294D), _nuevo),
                        const SizedBox(height: 12),
                        _buildActionButton('Grabar', Colors.cyanAccent, const Color(0xFF0A0E21), _grabar),
                        const SizedBox(height: 12),
                        _buildActionButton('Vista Previa', Colors.white, const Color(0xFF1F294D), _imprimirTicket),
                        const SizedBox(height: 12),
                        _buildActionButton('Imprimir', Colors.white, const Color(0xFF1F294D), _imprimirTicket),
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
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}