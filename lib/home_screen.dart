import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'category_screen.dart';
import 'client_screen.dart';
import 'supplier_screen.dart';
import 'product_screen.dart';
import 'user_screen.dart';
import 'sale_screen.dart';
import 'sales_history_screen.dart';

class HomeScreen extends StatelessWidget {
  final String usuarioActual; // Usuario que inició sesión

  const HomeScreen({super.key, this.usuarioActual = 'GIAN'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Menú Principal ($usuarioActual)', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, size: 70, color: Colors.cyanAccent),
              const SizedBox(height: 12),
              Text(
                '¡Bienvenido, $usuarioActual!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              
              // Mantenimiento de Categorías
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen())),
                  icon: const Icon(Icons.category, color: Color(0xFF0A0E21)),
                  label: const Text('Mantenimiento de Categorías', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 14),

              // Mantenimiento de Clientes
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientScreen())),
                  icon: const Icon(Icons.people, color: Color(0xFF0A0E21)),
                  label: const Text('Mantenimiento de Clientes', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 14),

              // Mantenimiento de Proveedores
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplierScreen())),
                  icon: const Icon(Icons.local_shipping, color: Color(0xFF0A0E21)),
                  label: const Text('Mantenimiento de Proveedores', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 14),

              // Mantenimiento de Productos
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductScreen())),
                  icon: const Icon(Icons.inventory_2, color: Color(0xFF0A0E21)),
                  label: const Text('Mantenimiento de Productos', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 14),

              // Mantenimiento de Usuarios
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserScreen())),
                  icon: const Icon(Icons.manage_accounts, color: Color(0xFF0A0E21)),
                  label: const Text('Mantenimiento de Usuarios', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 14),

              // Emisión de Boleta (Pasando el usuario actual)
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => SaleScreen(usuarioActual: usuarioActual),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long, color: Color(0xFF0A0E21)),
                  label: const Text('Emisión de Boleta y Factura', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 14),

              // Historial y Reporte de Ventas
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesHistoryScreen())),
                  icon: const Icon(Icons.history_edu, color: Color(0xFF0A0E21)),
                  label: const Text('Historial y Reporte de Ventas', style: TextStyle(color: Color(0xFF0A0E21), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}