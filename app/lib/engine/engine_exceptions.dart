/// Exceptions thrown by pure Dart Sus game engine.
class GameEngineException implements Exception {
  const GameEngineException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'GameEngineException($code): $message';
}
