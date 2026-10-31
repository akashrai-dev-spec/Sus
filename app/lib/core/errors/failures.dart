sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Unable to connect to game server. Please check your network.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server encountered an issue. Please try again.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class WrongPinFailure extends Failure {
  const WrongPinFailure([super.message = 'Wrong PIN. Try again.']);
}

class RateLimitedFailure extends Failure {
  const RateLimitedFailure(super.message);
}

class GameRuleFailure extends Failure {
  const GameRuleFailure(super.message);
}
