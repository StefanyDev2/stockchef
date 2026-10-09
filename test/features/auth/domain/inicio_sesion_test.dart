import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/features/auth/data/sesion_repositorio_firebase.dart';
import 'package:stockchef/features/auth/domain/inicio_sesion.dart';
import 'package:stockchef/features/auth/domain/perfil_usuario.dart';

void main() {
  group('DatosInicioSesion.validar (CA3)', () {
    test('pide ambos campos', () {
      expect(const DatosInicioSesion().validar(), {
        CampoInicioSesion.correo: MensajesInicioSesion.ingresaCorreo,
        CampoInicioSesion.contrasena: MensajesInicioSesion.ingresaContrasena,
      });
      expect(const DatosInicioSesion(correo: '  ', contrasena: 'x').validar(), {
        CampoInicioSesion.correo: MensajesInicioSesion.ingresaCorreo,
      });
    });

    test('con ambos campos no hay errores y el correo se normaliza', () {
      const datos = DatosInicioSesion(
        correo: ' Camila@Correo.com ',
        contrasena: 'Cocina12',
      );
      expect(datos.validar(), isEmpty);
      expect(datos.correoNormalizado, 'camila@correo.com');
    });
  });

  group('errores de Firebase Authentication', () {
    test(
      'CA8: correo desconocido y contraseña errada dan el mismo mensaje',
      () {
        for (final codigo in [
          'invalid-credential',
          'wrong-password',
          'user-not-found',
          'invalid-email',
        ]) {
          expect(esCredencialInvalida(codigo), isTrue, reason: codigo);
          expect(
            mensajeErrorInicioSesion(codigo),
            MensajesInicioSesion.credencialesInvalidas,
            reason: codigo,
          );
        }
      },
    );

    test('sin red pide revisar la conexión; lo demás es error general', () {
      expect(esCredencialInvalida('network-request-failed'), isFalse);
      expect(
        mensajeErrorInicioSesion('network-request-failed'),
        MensajesInicioSesion.sinConexion,
      );
      expect(
        mensajeErrorInicioSesion('user-disabled'),
        MensajesInicioSesion.cuentaDesactivada,
      );
      expect(
        mensajeErrorInicioSesion('internal-error'),
        MensajesInicioSesion.errorInterno,
      );
    });
  });

  test('CA10: el aviso de bloqueo dice la duración configurada', () {
    expect(
      MensajesInicioSesion.cuentaBloqueada(120),
      '🔒 Alcanzaste el número máximo de intentos. Tu cuenta está bloqueada '
      'por 2 horas.',
    );
    expect(MensajesInicioSesion.duracion(60), '1 hora');
    expect(MensajesInicioSesion.duracion(90), '90 minutos');
    expect(MensajesInicioSesion.duracion(1), '1 minuto');
  });

  group('perfil del usuario', () {
    test('lee el rol de Firestore y trata lo desconocido como sin rol', () {
      expect(Rol.desdeFirestore('administrador'), Rol.administrador);
      expect(Rol.desdeFirestore('auxiliar_cocina'), Rol.auxiliarCocina);
      for (final valor in [null, '', 'superadmin', 3]) {
        expect(Rol.desdeFirestore(valor), Rol.sinRol, reason: '$valor');
      }
    });

    test('construye el perfil del documento users/{uid}', () {
      final perfil = PerfilUsuario.desdeFirestore('u1', {
        'nombres': 'María José',
        'apellidos': 'Ruiz',
        'correo': 'mj@correo.com',
        'rol': 'auxiliar_cocina',
        'activo': true,
      });

      expect(perfil.rol, Rol.auxiliarCocina);
      expect(perfil.activo, isTrue);
      expect(perfil.nombreCompleto, 'María José Ruiz');
      expect(perfil.primerNombre, 'María');
    });

    test('sin el campo activo se considera desactivado', () {
      expect(PerfilUsuario.desdeFirestore('u1', {}).activo, isFalse);
      expect(
        PerfilUsuario.desdeFirestore('u1', {'activo': 'true'}).activo,
        isFalse,
      );
    });
  });
}
