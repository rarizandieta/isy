import '../../domain/failure.dart';

/// Traduce un [Failure] (categoría de la capa de datos) a un mensaje claro en
/// español para mostrar al usuario. El texto vive en la capa de UI.
String messageFor(Failure failure) {
  switch (failure.kind) {
    case FailureKind.invalidCredentials:
      return 'Correo o contraseña incorrectos.';
    case FailureKind.emailAlreadyRegistered:
      return 'Ese correo ya está registrado.';
    case FailureKind.network:
      return failure.detail ?? 'No se pudo conectar con el servidor.';
    case FailureKind.unknown:
      return failure.detail ?? 'Ocurrió un error inesperado.';
  }
}
