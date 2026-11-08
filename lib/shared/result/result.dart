sealed class Result<T> {}

final class Success<T> extends Result<T> {
  final T data;

  Success(this.data);
}

final class Failure<T> extends Result<T> {
  final Exception exception;

  Failure(this.exception);
}
