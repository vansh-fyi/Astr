abstract class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class CalculationFailure extends Failure {
  const CalculationFailure(super.message);
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}
