import '../domain/failure.dart';

/// Resultado de una operación que puede fallar con un [Failure].
///
/// Evita propagar excepciones entre capas: los repositorios devuelven
/// `Ok(value)` o `Err(failure)`, y los ViewModels reaccionan con un `switch`
/// exhaustivo (clase sellada).
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
