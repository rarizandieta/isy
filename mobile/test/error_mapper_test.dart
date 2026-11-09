// Prueba unitaria pura (sin plataforma) del mapeo de fallos a mensajes.
import 'package:flutter_test/flutter_test.dart';
import 'package:isy/core/errors/error_mapper.dart';
import 'package:isy/domain/failure.dart';

void main() {
  group('messageFor', () {
    test('credenciales inválidas', () {
      expect(
        messageFor(const Failure(FailureKind.invalidCredentials)),
        'Correo o contraseña incorrectos.',
      );
    });

    test('correo ya registrado', () {
      expect(
        messageFor(const Failure(FailureKind.emailAlreadyRegistered)),
        'Ese correo ya está registrado.',
      );
    });

    test('red: usa el detalle cuando existe', () {
      expect(
        messageFor(const Failure(FailureKind.network, 'sin conexión')),
        'sin conexión',
      );
    });

    test('desconocido: mensaje por defecto', () {
      expect(
        messageFor(const Failure(FailureKind.unknown)),
        'Ocurrió un error inesperado.',
      );
    });
  });
}
