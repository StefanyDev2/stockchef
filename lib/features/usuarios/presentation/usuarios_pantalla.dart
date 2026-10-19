import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../domain/usuarios.dart';
import 'etiqueta_rol.dart';
import 'usuarios_providers.dart';

/// Lo que el detalle le devuelve a la lista al guardar un cambio.
typedef CambioHecho = ({String uid, String mensaje});

/// Lista de usuarios del restaurante (HU-003, pantalla 2). Solo la abre el
/// administrador; las rutas muestran "sin permiso" a cualquier otro rol.
class UsuariosPantalla extends ConsumerStatefulWidget {
  const UsuariosPantalla({super.key, required this.administrador});

  final PerfilUsuario administrador;

  @override
  ConsumerState<UsuariosPantalla> createState() => _UsuariosPantallaState();
}

class _UsuariosPantallaState extends ConsumerState<UsuariosPantalla> {
  /// Aviso verde y usuario resaltado después de un cambio (pantallas 4 y D1).
  CambioHecho? _ultimoCambio;

  Future<void> _abrir(PerfilUsuario usuario) async {
    final cambio = await context.push<CambioHecho>(
      Rutas.detalleUsuario(usuario.uid),
    );
    if (mounted) setState(() => _ultimoCambio = cambio);
  }

  void _volver() => context.canPop() ? context.pop() : context.go(Rutas.inicio);

  @override
  Widget build(BuildContext context) {
    final usuarios = ref.watch(
      usuariosProvider(widget.administrador.restaurantId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: _volver,
        ),
        title: const TituloResaltado('Usuarios'),
      ),
      body: SafeArea(
        child: usuarios.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.verde),
          ),
          error: (_, _) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                MensajesUsuarios.errorLista,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (lista) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              if (_ultimoCambio != null) ...[
                _AvisoExito(_ultimoCambio!.mensaje),
                const SizedBox(height: 16),
              ],
              for (final usuario in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TarjetaUsuario(
                    usuario: usuario,
                    resaltado: usuario.uid == _ultimoCambio?.uid,
                    alTocar: () => _abrir(usuario),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de cada usuario (CA2): nombres, apellidos, correo y rol.
class _TarjetaUsuario extends StatelessWidget {
  const _TarjetaUsuario({
    required this.usuario,
    required this.resaltado,
    required this.alTocar,
  });

  final PerfilUsuario usuario;
  final bool resaltado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: resaltado ? AppColors.verdeFondo : AppColors.fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: resaltado ? AppColors.verde : AppColors.borde,
          width: resaltado ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tinta,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.correo,
                      style: const TextStyle(color: AppColors.atenuado),
                    ),
                    const SizedBox(height: 8),
                    EtiquetaRol(usuario: usuario),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.atenuado),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvisoExito extends StatelessWidget {
  const _AvisoExito(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.menta,
          border: Border.all(color: AppColors.verde),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.verdeTexto,
          ),
        ),
      ),
    );
  }
}
