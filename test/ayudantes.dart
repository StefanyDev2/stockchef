import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/app.dart';
import 'package:stockchef/features/auth/domain/inicio_sesion.dart';
import 'package:stockchef/features/auth/domain/perfil_usuario.dart';
import 'package:stockchef/features/auth/presentation/sesion_controlador.dart';
import 'package:stockchef/features/compras/domain/compras.dart';
import 'package:stockchef/features/compras/domain/unidades.dart';
import 'package:stockchef/features/compras/presentation/compras_providers.dart';
import 'package:stockchef/features/insumos/domain/insumos.dart';
import 'package:stockchef/features/insumos/presentation/insumos_providers.dart';
import 'package:stockchef/features/usuarios/domain/usuarios.dart';
import 'package:stockchef/features/usuarios/presentation/usuarios_providers.dart';

PerfilUsuario perfilDePrueba({
  String nombres = 'Camila',
  String apellidos = 'Ruiz',
  String? uid,
  Rol rol = Rol.administrador,
  bool activo = true,
}) => PerfilUsuario(
  uid: uid ?? 'uid-$nombres',
  nombres: nombres,
  apellidos: apellidos,
  correo: '${nombres.toLowerCase()}@correo.com',
  restaurantId: 'sabor-casero',
  rol: rol,
  activo: activo,
);

/// Sesión falsa. Por defecto acepta camila@correo.com / Cocina12 como
/// administradora y rechaza todo lo demás.
class SesionFalsa implements SesionRepositorio {
  SesionFalsa({this.guardada});

  /// Perfil de la sesión que "quedó abierta" al cerrar la app.
  PerfilUsuario? guardada;

  /// Si tiene valor, se responde esto en lugar de revisar las credenciales.
  ResultadoInicioSesion? respuesta;
  PerfilUsuario perfil = perfilDePrueba();
  Completer<void>? pausa;

  final intentos = <DatosInicioSesion>[];
  var sesionesCerradas = 0;

  @override
  Future<ResultadoInicioSesion> iniciarSesion(DatosInicioSesion datos) async {
    intentos.add(datos);
    await pausa?.future;
    if (respuesta != null) return respuesta!;
    final correcto =
        datos.correoNormalizado == 'camila@correo.com' &&
        datos.contrasena == 'Cocina12';
    return correcto
        ? SesionIniciada(perfil)
        : const SesionRechazada(MensajesInicioSesion.credencialesInvalidas);
  }

  @override
  Future<PerfilUsuario?> sesionGuardada() async => guardada;

  @override
  Future<void> cerrarSesion() async {
    sesionesCerradas++;
    guardada = null;
  }
}

/// Abre la app completa con un teléfono de 360 × 800 y la sesión falsa.
Future<void> abrirApp(
  WidgetTester tester, {
  SesionFalsa? sesion,
  UsuariosFalsos? usuarios,
  ComprasFalsas? compras,
  InsumosFalsos? insumos,
  Size tamano = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sesionRepositorioProvider.overrideWithValue(sesion ?? SesionFalsa()),
        usuariosRepositorioProvider.overrideWithValue(
          usuarios ?? UsuariosFalsos(),
        ),
        comprasRepositorioProvider.overrideWithValue(
          compras ?? ComprasFalsas(),
        ),
        insumosRepositorioProvider.overrideWithValue(
          insumos ?? InsumosFalsos(),
        ),
      ],
      child: const StockChefApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Usuarios del restaurante en memoria. Aplica los cambios como lo haría el
/// servidor, salvo que `respuesta` diga otra cosa.
class UsuariosFalsos implements UsuariosRepositorio {
  UsuariosFalsos([List<PerfilUsuario>? iniciales])
    : _usuarios = {for (final u in iniciales ?? const []) u.uid: u};

  final Map<String, PerfilUsuario> _usuarios;
  final _cambios = StreamController<List<PerfilUsuario>>.broadcast();

  /// Si tiene valor, se responde esto y no se cambia nada.
  ResultadoCambio? respuesta;
  final llamadas = <String>[];

  List<PerfilUsuario> get _lista => ordenarUsuarios(_usuarios.values);

  PerfilUsuario usuario(String uid) => _usuarios[uid]!;

  @override
  Stream<List<PerfilUsuario>> usuariosDe(String restaurantId) async* {
    yield _lista;
    yield* _cambios.stream;
  }

  ResultadoCambio _cambiar(String uid, {Rol? rol, bool? activo}) {
    if (respuesta != null) return respuesta!;
    final u = _usuarios[uid]!;
    _usuarios[uid] = PerfilUsuario(
      uid: u.uid,
      nombres: u.nombres,
      apellidos: u.apellidos,
      correo: u.correo,
      restaurantId: u.restaurantId,
      rol: rol ?? u.rol,
      activo: activo ?? u.activo,
    );
    _cambios.add(_lista);
    return const CambioGuardado();
  }

  @override
  Future<ResultadoCambio> asignarRol(String uid, Rol rol) async {
    llamadas.add('asignarRol $uid ${rol.name}');
    return _cambiar(uid, rol: rol);
  }

  @override
  Future<ResultadoCambio> cambiarEstado(
    String uid, {
    required bool activo,
  }) async {
    llamadas.add('cambiarEstado $uid $activo');
    return _cambiar(uid, activo: activo);
  }
}

/// Insumos y compras en memoria. Guarda como lo haría el servidor (sin
/// convertir unidades), salvo que `respuesta` diga otra cosa.
class ComprasFalsas implements ComprasRepositorio {
  ComprasFalsas([List<Insumo>? insumos])
    : insumos =
          insumos ??
          const [
            Insumo(
              id: 'tomate',
              nombre: 'Tomate',
              unidad: UnidadMedida.kilogramo,
              cantidadDisponible: 5,
            ),
            Insumo(
              id: 'aceite',
              nombre: 'Aceite',
              unidad: UnidadMedida.litro,
              cantidadDisponible: 3,
            ),
          ];

  final List<Insumo> insumos;
  final guardadas = <Compra>[];
  final enviados = <Map<String, Object?>>[];
  final _cambios = StreamController<List<Compra>>.broadcast();

  ResultadoCompra? respuesta;

  @override
  Stream<List<Insumo>> insumosActivos(String restaurantId) =>
      Stream.value(insumos);

  @override
  Stream<List<Compra>> compras(String restaurantId) async* {
    yield guardadas.reversed.toList();
    yield* _cambios.stream;
  }

  @override
  Future<ResultadoCompra> registrar(DatosCompra datos) async {
    enviados.add(datos.aEnvio());
    if (respuesta != null) return respuesta!;
    final envio = datos.aEnvio();
    final insumo = insumos.firstWhere((i) => i.id == datos.insumoId);
    final cantidad = envio['cantidad']! as double;
    final precio = envio['precioTotal']! as double;
    final compra = Compra(
      id: 'c${guardadas.length + 1}',
      insumoNombre: insumo.nombre,
      tipo: datos.tipo,
      cantidad: cantidad,
      unidad: datos.unidad!,
      proveedor: envio['proveedor'] as String?,
      precioTotal: precio,
      precioUnitario: precio / cantidad,
      cantidadDisponibleDespues: insumo.cantidadDisponible + cantidad,
      unidadInsumo: insumo.unidad,
    );
    guardadas.add(compra);
    _cambios.add(guardadas.reversed.toList());
    return CompraGuardada(compra);
  }
}

/// Insumos registrados en memoria (HU-004). Guarda la lista de críticos como
/// lo haría el servidor, salvo que `respuesta` diga otra cosa.
class InsumosFalsos implements InsumosRepositorio {
  InsumosFalsos([List<InsumoRegistrado>? iniciales])
    : _insumos =
          iniciales ??
          const [
            InsumoRegistrado(
              id: 'tomate',
              nombre: 'Tomate',
              activo: true,
              critico: true,
            ),
            InsumoRegistrado(
              id: 'arroz',
              nombre: 'Arroz',
              activo: true,
              critico: false,
            ),
            InsumoRegistrado(
              id: 'pollo',
              nombre: 'Pollo',
              activo: true,
              critico: false,
            ),
            InsumoRegistrado(
              id: 'cebolla',
              nombre: 'Cebolla',
              activo: false,
              critico: false,
            ),
          ];

  List<InsumoRegistrado> _insumos;
  final _cambios = StreamController<List<InsumoRegistrado>>.broadcast();

  ResultadoGuardado? respuesta;
  final guardados = <Set<String>>[];

  Set<String> get criticos => {
    for (final i in _insumos)
      if (i.critico) i.id,
  };

  @override
  Stream<List<InsumoRegistrado>> insumosDe(String restaurantId) async* {
    yield _insumos;
    yield* _cambios.stream;
  }

  @override
  Future<ResultadoGuardado> guardarCriticos(Set<String> criticos) async {
    guardados.add(criticos);
    if (respuesta != null) return respuesta!;
    _insumos = [
      for (final i in _insumos)
        InsumoRegistrado(
          id: i.id,
          nombre: i.nombre,
          activo: i.activo,
          critico: criticos.contains(i.id),
        ),
    ];
    _cambios.add(_insumos);
    return const ListaGuardada();
  }
}
