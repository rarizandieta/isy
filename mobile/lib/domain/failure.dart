/// Categoría semántica de un fallo de la capa de datos, independiente de la UI.
/// La capa de UI decide el texto que se muestra (ver core/errors/error_mapper).
enum FailureKind {
  invalidCredentials,
  emailAlreadyRegistered,
  network,
  unknown,
}

/// Fallo de dominio producido por la capa de datos (repositorios). No contiene
/// texto para el usuario: solo la categoría + un detalle opcional de origen.
class Failure {
  final FailureKind kind;

  /// Detalle opcional de la fuente (p. ej. el mensaje del backend) para el caso
  /// `unknown`/`network`. No se muestra tal cual salvo que la UI lo decida.
  final String? detail;

  const Failure(this.kind, [this.detail]);
}
