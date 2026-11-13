import 'package:flutter/material.dart';
import 'main.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedSexo = 'F';
  final List<String> _sexos = ['F', 'M'];

  String _selectedDistrito = 'ATE';
  final List<String> _distritos = ['ATE', 'SANTA ANITA', 'LA VICTORIA', 'JESUS MARIA', 'SAN ISIDRO', 'COMAS', 'SAN LUIS'];

  String _selectedActivo = '1';
  final List<String> _activos = ['1', '0'];

  String _selectedNivel = '1';
  final List<String> _niveles = ['1', '2', '3'];

  List<dynamic> _usuarios = [];
  bool _isLoading = false;
  String? _selectedUserCodigo;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('usuario')
          .select()
          .order('usu_cod', ascending: true);
      
      setState(() {
        _usuarios = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar usuarios: $e', Colors.redAccent);
    }
  }

  Future<void> _grabar() async {
    final nombre = _nombreController.text.trim();
    final dni = _dniController.text.trim();
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty || dni.isEmpty || login.isEmpty) {
      _mostrarMensaje('Complete Nombre, DNI y Login', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resMax = await supabase
          .from('usuario')
          .select('usu_cod')
          .order('usu_cod', ascending: false)
          .limit(1);

      String nuevoCodigo = 'U0001';
      if ((resMax as List).isNotEmpty) {
        String ultimoCod = resMax[0]['usu_cod'].toString();
        int num = int.parse(ultimoCod.substring(1)) + 1;
        nuevoCodigo = 'U${num.toString().padLeft(4, '0')}';
      }

      await supabase.from('usuario').insert({
        'usu_cod': nuevoCodigo,
        'usu_dni': dni,
        'usu_nombre': nombre.toUpperCase(),
        'usu_direc': _direccionController.text.trim().toUpperCase(),
        'usu_dist': _selectedDistrito,
        'usu_telef': _telefonoController.text.trim(),
        'usu_mail': _emailController.text.trim(),
        'fec_nac': '10/08/1989',
        'sexo': _selectedSexo,
        'nivel': int.parse(_selectedNivel),
        'usu_login': login,
        'usu_password': password,
        'activo': int.parse(_selectedActivo),
      });

      _nuevo();
      _cargarUsuarios();
      _mostrarMensaje('Usuario guardado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al guardar: $e', Colors.redAccent);
    }
  }

  Future<void> _modificar() async {
    if (_selectedUserCodigo == null) {
      _mostrarMensaje('Seleccione un usuario de la tabla para modificar', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('usuario')
          .update({
            'usu_dni': _dniController.text.trim(),
            'usu_nombre': _nombreController.text.trim().toUpperCase(),
            'usu_direc': _direccionController.text.trim().toUpperCase(),
            'usu_dist': _selectedDistrito,
            'usu_telef': _telefonoController.text.trim(),
            'usu_mail': _emailController.text.trim(),
            'sexo': _selectedSexo,
            'nivel': int.parse(_selectedNivel),
            'usu_login': _loginController.text.trim(),
            'usu_password': _passwordController.text.trim(),
            'activo': int.parse(_selectedActivo),
          })
          .eq('usu_cod', _selectedUserCodigo!);

      _nuevo();
      _cargarUsuarios();
      _mostrarMensaje('Usuario modificado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al modificar: $e', Colors.redAccent);
    }
  }

  Future<void> _eliminar() async {
    if (_selectedUserCodigo == null) {
      _mostrarMensaje('Seleccione un usuario de la tabla para eliminar', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('usuario')
          .delete()
          .eq('usu_cod', _selectedUserCodigo!);

      _nuevo();
      _cargarUsuarios();
      _mostrarMensaje('Usuario eliminado con éxito', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al eliminar: $e', Colors.redAccent);
    }
  }

  void _buscar() {
    final filtro = _nombreController.text.trim().toLowerCase();
    final dniFiltro = _dniController.text.trim().toLowerCase();
    if (filtro.isEmpty && dniFiltro.isEmpty) {
      _cargarUsuarios();
      return;
    }
    setState(() {
      _usuarios = _usuarios.where((u) => 
        u['usu_nombre'].toString().toLowerCase().contains(filtro) ||
        u['usu_dni'].toString().toLowerCase().contains(dniFiltro) ||
        u['usu_cod'].toString().toLowerCase().contains(filtro)
      ).toList();
    });
  }

  void _nuevo() {
    _nombreController.clear();
    _dniController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _loginController.clear();
    _passwordController.clear();
    setState(() {
      _selectedUserCodigo = null;
      _selectedSexo = 'F';
      _selectedDistrito = 'ATE';
      _selectedActivo = '1';
      _selectedNivel = '1';
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
        title: const Text('Mantenimiento de Usuarios', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna principal con formulario y tabla
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos del Usuario',
                          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Apellidos y Nombre(s):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 3),
                                  TextField(
                                    controller: _nombreController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DNI:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 3),
                                  TextField(
                                    controller: _dniController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sexo:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 3),
                                  DropdownButtonFormField<String>(
                                    value: _selectedSexo,
                                    dropdownColor: const Color(0xFF131A36),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                    items: _sexos.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                    onChanged: (val) => setState(() => _selectedSexo = val!),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dirección:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 3),
                                  TextField(
                                    controller: _direccionController,
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
                                  const Text('Distrito:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 3),
                                  DropdownButtonFormField<String>(
                                    value: _selectedDistrito,
                                    dropdownColor: const Color(0xFF131A36),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(),
                                    items: _distritos.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                    onChanged: (val) => setState(() => _selectedDistrito = val!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Teléfono:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 3),
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
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('E-mail:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 3),
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seguridad', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Login:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                        const SizedBox(height: 3),
                                        TextField(
                                          controller: _loginController,
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
                                        const Text('Contraseña:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                        const SizedBox(height: 3),
                                        TextField(
                                          controller: _passwordController,
                                          obscureText: true,
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
                                        const Text('Activo:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                        const SizedBox(height: 3),
                                        DropdownButtonFormField<String>(
                                          value: _selectedActivo,
                                          dropdownColor: const Color(0xFF131A36),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: _inputDecoration(),
                                          items: _activos.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                                          onChanged: (val) => setState(() => _selectedActivo = val!),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Text('Priv. Nivel: ', style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                                    SizedBox(
                                      width: 50,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedNivel,
                                        dropdownColor: const Color(0xFF131A36),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: _inputDecoration(),
                                        items: _niveles.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                                        onChanged: (val) => setState(() => _selectedNivel = val!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Desc: ', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                    Expanded(
                                      child: Text(
                                        _selectedNivel == '1' ? 'ADMINISTRADOR' : _selectedNivel == '2' ? 'SUPERVISOR' : 'OPERADOR',
                                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tabla con altura fija para permitir el desplazamiento general
                  Container(
                    height: 250,
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
                                    DataColumn(label: Text('Nombre', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('DNI', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Sexo', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Login', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nivel', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _usuarios.map((u) {
                                    final isSelected = _selectedUserCodigo == u['usu_cod'];
                                    return DataRow(
                                      selected: isSelected,
                                      onSelectChanged: (selected) {
                                        setState(() {
                                          _selectedUserCodigo = u['usu_cod'];
                                          _nombreController.text = u['usu_nombre'] ?? '';
                                          _dniController.text = u['usu_dni'] ?? '';
                                          _direccionController.text = u['usu_direc'] ?? '';
                                          _telefonoController.text = u['usu_telef'] ?? '';
                                          _emailController.text = u['usu_mail'] ?? '';
                                          _loginController.text = u['usu_login'] ?? '';
                                          _passwordController.text = u['usu_password'] ?? '';
                                          if (_sexos.contains(u['sexo'])) _selectedSexo = u['sexo'];
                                          if (_distritos.contains(u['usu_dist'])) _selectedDistrito = u['usu_dist'];
                                          if (_activos.contains(u['activo']?.toString())) _selectedActivo = u['activo'].toString();
                                          if (_niveles.contains(u['nivel']?.toString())) _selectedNivel = u['nivel'].toString();
                                        });
                                      },
                                      cells: [
                                        DataCell(Text(u['usu_cod'] ?? '', style: const TextStyle(color: Colors.white))),
                                        DataCell(Text(u['usu_nombre'] ?? '', style: const TextStyle(color: Colors.white))),
                                        DataCell(Text(u['usu_dni'] ?? '', style: const TextStyle(color: Colors.white))),
                                        DataCell(Text(u['sexo'] ?? '', style: const TextStyle(color: Colors.white))),
                                        DataCell(DataCell(Text(u['usu_login'] ?? '', style: const TextStyle(color: Colors.white))).child),
                                        DataCell(Text(u['nivel']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Botones laterales de acción
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