import 'package:astr/core/error/failure.dart';

/// A Result type that represents either a success or a failure.
/// This pattern ensures explicit error handling without throwing exceptions.
sealed class Result<T> {
  const Result();

  /// Creates a successful result with a value
  factory Result.success(T value) = Success<T>;

  /// Creates a failed result with a Failure
  factory Result.failure(Failure failure) = Failed<T>;

  /// Returns true if this is a successful result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failed result
  bool get isFailure => this is Failed<T>;

  /// Returns the value if successful, otherwise throws
  T get value {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw StateError('Cannot get value from a failed result');
  }

  /// Returns the failure if failed, otherwise throws
  Failure get failure {
    if (this is Failed<T>) {
      return (this as Failed<T>).failure;
    }
    throw StateError('Cannot get failure from a successful result');
  }

  /// Executes onSuccess if successful, otherwise executes onFailure
  R fold<R>(R Function(T value) onSuccess, R Function(Failure failure) onFailure) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onFailure((this as Failed<T>).failure);
    }
  }

  /// Maps the value if successful, otherwise returns the failed result
  Result<R> map<R>(R Function(T value) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).value));
    } else {
      return Result.failure((this as Failed<T>).failure);
    }
  }

  /// Flat maps the value if successful, otherwise returns the failed result
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    if (this is Success<T>) {
      return transform((this as Success<T>).value);
    } else {
      return Result.failure((this as Failed<T>).failure);
    }
  }
}

/// Represents a successful result containing a value
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Represents a failed result containing a Failure
final class Failed<T> extends Result<T> {
  final Failure failure;
  const Failed(this.failure);

  @override
  String toString() => 'Failed($failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}
