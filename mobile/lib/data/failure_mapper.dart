import '../domain/failure.dart';
import 'api_exception.dart';

/// Traduce excepciones de la capa de servicios ([ApiException]/[NetworkException])
/// a un [Failure] de dominio. Fuente única usada por los repositorios.
Failure failureFromError(Object error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return const Failure(FailureKind.invalidCredentials);
      case 409:
        return const Failure(FailureKind.emailAlreadyRegistered);
      default:
        return Failure(FailureKind.unknown, error.message);
    }
  }
  if (error is NetworkException) {
    return Failure(FailureKind.network, error.message);
  }
  return const Failure(FailureKind.unknown);
}
