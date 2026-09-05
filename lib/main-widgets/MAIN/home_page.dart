import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/CALZADO/calzado_page.dart';
import 'package:zapatito_v2/main-widgets/DUENO_MUESTRA/dueno_muestra_page.dart';
import 'package:zapatito_v2/main-widgets/INVENTARIO/inventario_page.dart';
import 'package:zapatito_v2/main-widgets/TIPO_CALZADO/tipo_calzado_page.dart';
import 'package:zapatito_v2/main-widgets/VENTA/venta_page.dart';
import 'package:zapatito_v2/services/API/usuario.dart';
import 'package:zapatito_v2/services/local_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  String? firstName;
  String? emailUser;
  String? propietarioId;
  String? inventarioId;
  String? rolName;

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final data = await LocalStorageService.getUserData();
    final userEmail = data['email'];

    setState(() {
      userName = data['name'] ?? 'Invitado';
      firstName = userName;
      emailUser = userEmail;
    });
    if (userEmail != null && userEmail.toString().isNotEmpty) {
      final usuarioData =
          await UsuarioService.obtenerUsuarioPorEmail(userEmail);

      if (mounted) {
        if (usuarioData != null) {
          setState(() {
            rolName = usuarioData['nombre_rol'] ?? 'Sin Rol';
            inventarioId = usuarioData['id_inventario']?.toString();
            propietarioId = usuarioData['id_usuario']?.toString();
          });
        } else {
          setState(() {
            rolName = 'Sin Rol';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          rolName = 'Invitado';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = rolName == "Administrador";
    final bool isVendedor = rolName == "Vendedor";
    final bool isAlmacenero = rolName == "Almacenero";

    return Scaffold(
      appBar: Designwidgets().appBarMain("Principal"),
      body: (rolName == null)
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Cargando perfil y permisos..."),
                ],
              ),
            )
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Hola $firstName 👋',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Rol: $rolName',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  if (isAdmin || isAlmacenero)
                    _buildMenuButton(
                      context,
                      label: 'Dueños de Muestras',
                      page: DuenoMuestraPage(
                          firstName: firstName,
                          emailUser: emailUser,
                          inventarioId: inventarioId),
                    ),
                  if (isAdmin || isAlmacenero)
                    _buildMenuButton(
                      context,
                      label: 'Tipos de Calzados',
                      page: TipoCalzadoPage(
                          firstName: firstName,
                          emailUser: emailUser,
                          inventarioId: inventarioId),
                    ),
                  if (isAdmin || isAlmacenero)
                    _buildMenuButton(
                      context,
                      label: 'Códigos',
                      page: CalzadoPage(
                          firstName: firstName,
                          emailUser: emailUser,
                          inventarioId: inventarioId,
                          isAlmacenero: isAlmacenero),
                    ),
                if (isAdmin || isAlmacenero)
                  _buildMenuButton(
                    context,
                    label: 'Inventario',
                    page: InventarioPage(
                        firstName: firstName,
                        emailUser: emailUser,
                        inventarioId: inventarioId,
                        isVendedor: isVendedor),
                  ),
                if (isAdmin || isVendedor || isAlmacenero)
                  _buildMenuButton(
                    context,
                    label: 'Ventas',
                    page: VentaPage(
                        firstName: firstName,
                        emailUser: emailUser,
                        inventarioId: inventarioId),
                  ),
                ],
              ),
            ),
      drawer: Designwidgets().drawerHome(context, firstName ?? "Invitado"),
    );
  }

// Función auxiliar para no repetir código de diseño de botones
  Widget _buildMenuButton(BuildContext context,
      {required String label, required Widget page}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: 200,
        child: MaterialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          color: const Color.fromARGB(255, 33, 47, 243),
          textColor: Colors.white,
          child: Text(label),
        ),
      ),
    );
  }
}
