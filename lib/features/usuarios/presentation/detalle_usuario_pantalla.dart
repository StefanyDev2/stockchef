import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../../inicio/presentation/avatar_usuario.dart';
import '../domain/usuarios.dart';
import 'etiqueta_rol.dart';
import 'usuarios_pantalla.dart';
import 'usuarios_providers.dart';

/// Detalle de un usuario (HU-003, pantalla 3): asignar rol, desactivar o
/// reactivar. Los errores del servidor se muestran arriba en rojo (E1).
class DetalleUsuarioPantalla extends ConsumerStatefulWidget {
  const DetalleUsuarioPantalla({
    super.key,
    required this.administrador,
    required this.uid,
  });

  final PerfilUsuario administrador;
  final String uid;

  @override
  ConsumerState<DetalleUsuarioPantalla> createState() =>
      _DetalleUsuarioPantallaState();
}

class _DetalleUsuarioPantallaState
    extends ConsumerState<DetalleUsuarioPantalla> {
  /// Rol elegido en la lista; `null` mientras no se elija (usuario sin rol).
  Rol? _elegido;
  bool _inicializado = false;
  bool _guardando = false;
  String? _error;

  void _volver([CambioHecho? cambio]) {
    if (context.canPop()) {
      context.pop(cambio);
    } else {
      context.go(Rutas.usuarios);
    }
  }

  Future<void> _aplicar(
    Future<ResultadoCambio> Function(UsuariosRepositorio repositorio) cambio,
    String mensajeExito,
  ) async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    final resultado = await cambio(ref.read(usuariosRepositorioProvider));
    if (!mounted) return;
    setState(() => _guardando = false);

    switch (resultado) {
      case CambioGuardado():
        _volver((uid: widget.uid, mensaje: mensajeExito));
      case CambioRechazado(:final mensaje):
        setState(() => _error = mensaje);
      case CambioSinPermiso():
        context.go(Rutas.sinPermiso);
    }
  }

  Future<void> _guardarRol() => _aplicar(
    (r) => r.asignarRol(widget.uid, _elegido!),
    MensajesUsuarios.rolActualizado,
  );

  Future<void> _cambiarEstado(PerfilUsuario usuario) async {
    final desactivar = usuario.activo;
    if (desactivar && !await _confirmarDesactivar(usuario)) return;
    await _aplicar(
      (r) => r.cambiarEstado(widget.uid, activo: !desactivar),
      desactivar
          ? MensajesUsuarios.usuarioDesactivado
          : MensajesUsuarios.usuarioReactivado,
    );
  }

  Future<bool> _confirmarDesactivar(PerfilUsuario usuario) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Desactivar a ${usuario.nombreCompleto}?'),
        content: const Text(
          'No podrá ingresar a la aplicación hasta que lo reactives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = ref.watch(
      usuariosProvider(widget.administrador.restaurantId),
    );
    final usuario = usuarios.value
        ?.where((u) => u.uid == widget.uid)
        .firstOrNull;

    if (usuario != null && !_inicializado) {
      _inicializado = true;
      _elegido = rolesAsignables.contains(usuario.rol) ? usuario.rol : null;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: _guardando ? null : _volver,
        ),
        title: const TituloResaltado('Detalle de usuario'),
      ),
      body: SafeArea(
        child: switch ((usuarios, usuario)) {
          (AsyncLoading(), _) => const Center(
            child: CircularProgressIndicator(color: AppColors.verde),
          ),
          (_, null) => const Center(child: Text('No se encontró el usuario.')),
          (_, final PerfilUsuario u) => _contenido(u),
        },
      ),
    );
  }

  Widget _contenido(PerfilUsuario usuario) {
    final cambioRol = _elegido != null && _elegido != usuario.rol;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Center(child: AvatarUsuario(tamano: 88)),
        const SizedBox(height: 12),
        Text(
          usuario.nombreCompleto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.tinta,
          ),
        ),
        Text(
          usuario.correo,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.atenuado),
        ),
        const SizedBox(height: 8),
        Center(
          child: EtiquetaRol(usuario: usuario, prefijo: 'Rol actual: '),
        ),
        const SizedBox(height: 24),
        const Text(
          'Asignar rol',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.tinta,
          ),
        ),
        const SizedBox(height: 12),
        for (final rol in rolesAsignables)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OpcionRol(
              rol: rol,
              elegido: _elegido == rol,
              habilitado: !_guardando,
              alElegir: () => setState(() {
                _elegido = rol;
                _error = null;
              }),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.naranja,
            foregroundColor: Colors.white,
          ),
          onPressed: cambioRol && !_guardando ? _guardarRol : null,
          child: _guardando
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Guardar cambios'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: usuario.activo ? AppColors.error : AppColors.verde,
            side: BorderSide(
              color: usuario.activo ? AppColors.error : AppColors.verde,
            ),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          onPressed: _guardando ? null : () => _cambiarEstado(usuario),
          child: Text(
            usuario.activo ? 'Desactivar usuario' : 'Reactivar usuario',
          ),
        ),
      ],
    );
  }
}

/// Opción de la lista de roles (CA3): durazno cuando está elegida.
class _OpcionRol extends StatelessWidget {
  const _OpcionRol({
    required this.rol,
    required this.elegido,
    required this.habilitado,
    required this.alElegir,
  });

  final Rol rol;
  final bool elegido;
  final bool habilitado;
  final VoidCallback alElegir;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: elegido,
      button: true,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: elegido ? AppColors.durazno : AppColors.fondo,
          foregroundColor: AppColors.tinta,
          side: BorderSide(
            color: elegido ? AppColors.duraznoBorde : AppColors.tinta,
            width: elegido ? 1.5 : 1,
          ),
          minimumSize: const Size.fromHeight(48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        onPressed: habilitado ? alElegir : null,
        child: Row(
          children: [
            Expanded(child: Text(rol.etiqueta)),
            if (elegido) const Icon(Icons.check_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
