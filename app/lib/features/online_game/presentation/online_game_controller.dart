import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});

class OnlineState {
  const OnlineState({
    this.isConnected = false,
    this.playerId,
    this.roomState,
    this.myRole,
    this.mySecretWord,
    this.myCategory,
    this.liveClues = const [],
    this.latestAccusation,
    this.gameEndedData,
  });

  final bool isConnected;
  final String? playerId;
  final Map<String, dynamic>? roomState;
  final String? myRole;
  final String? mySecretWord;
  final String? myCategory;
  final List<Map<String, dynamic>> liveClues;
  final Map<String, dynamic>? latestAccusation;
  final Map<String, dynamic>? gameEndedData;

  bool get isHost {
    if (roomState == null || playerId == null) return false;
    return roomState!['hostId'] == playerId;
  }

  bool get isImposter => myRole == 'imposter';

  OnlineState copyWith({
    bool? isConnected,
    String? playerId,
    Map<String, dynamic>? roomState,
    String? myRole,
    String? mySecretWord,
    String? myCategory,
    List<Map<String, dynamic>>? liveClues,
    Map<String, dynamic>? latestAccusation,
    Map<String, dynamic>? gameEndedData,
  }) {
    return OnlineState(
      isConnected: isConnected ?? this.isConnected,
      playerId: playerId ?? this.playerId,
      roomState: roomState ?? this.roomState,
      myRole: myRole ?? this.myRole,
      mySecretWord: mySecretWord ?? this.mySecretWord,
      myCategory: myCategory ?? this.myCategory,
      liveClues: liveClues ?? this.liveClues,
      latestAccusation: latestAccusation ?? this.latestAccusation,
      gameEndedData: gameEndedData ?? this.gameEndedData,
    );
  }
}

final onlineGameControllerProvider =
    StateNotifierProvider<OnlineGameNotifier, OnlineState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final profile = ref.watch(userProfileProvider);
  return OnlineGameNotifier(socketService, profile);
});

class OnlineGameNotifier extends StateNotifier<OnlineState> {
  OnlineGameNotifier(this._socket, this._profile)
      : super(const OnlineState()) {
    _init();
  }

  final SocketService _socket;
  final UserProfile _profile;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void _init() {
    _socket.connect(
      serverUrl: _profile.serverUrl,
      name: _profile.name,
      color: _profile.color,
      resumeToken: _profile.resumeToken,
    );

    _subscriptions.add(
      _socket.onConnectionChanged.listen((connected) {
        if (mounted) {
          state = state.copyWith(isConnected: connected);
        }
      }),
    );

    _subscriptions.add(
      _socket.onRoomState.listen((data) {
        if (!mounted) return;
        final rawClues = data['clues'] as List?;
        final clues = rawClues != null
            ? rawClues.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : state.liveClues;

        state = state.copyWith(
          roomState: data,
          liveClues: clues,
        );
      }),
    );

    _subscriptions.add(
      _socket.onRole.listen((data) {
        if (!mounted) return;
        state = state.copyWith(
          myRole: data['role'] as String?,
          mySecretWord: data['word'] as String?,
          myCategory: data['category'] as String?,
        );
      }),
    );

    _subscriptions.add(
      _socket.onClue.listen((clue) {
        if (!mounted) return;
        state = state.copyWith(
          liveClues: [...state.liveClues, clue],
        );
      }),
    );

    _subscriptions.add(
      _socket.onAccusation.listen((accuse) {
        if (!mounted) return;
        state = state.copyWith(latestAccusation: accuse);
      }),
    );

    _subscriptions.add(
      _socket.onEnded.listen((ended) {
        if (!mounted) return;
        state = state.copyWith(gameEndedData: ended);
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  Future<bool> ensureConnected() async {
    if (_socket.isConnected) return true;

    _socket.connect(
      serverUrl: _profile.serverUrl,
      name: _profile.name,
      color: _profile.color,
      resumeToken: _profile.resumeToken,
    );

    try {
      await _socket.onConnectionChanged
          .firstWhere((connected) => connected)
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return _socket.isConnected;
    }
  }

  Future<Map<String, dynamic>> createRoom({
    required String name,
    required String pin,
    required Map<String, dynamic> settings,
  }) async {
    final res = await _socket.createRoom(name: name, pin: pin, settings: settings);
    if (res['ok'] == true && res['data'] != null) {
      state = state.copyWith(roomState: Map<String, dynamic>.from(res['data'] as Map));
    }
    return res;
  }

  Future<Map<String, dynamic>> joinRoom({
    required String roomId,
    required String pin,
  }) async {
    final res = await _socket.joinRoom(roomId: roomId, pin: pin);
    if (res['ok'] == true && res['data'] != null) {
      state = state.copyWith(roomState: Map<String, dynamic>.from(res['data'] as Map));
    }
    return res;
  }

  Future<void> leaveRoom() async {
    await _socket.leaveRoom();
    state = state.copyWith(
      roomState: null,
      myRole: null,
      mySecretWord: null,
      myCategory: null,
      liveClues: [],
      latestAccusation: null,
      gameEndedData: null,
    );
  }

  Future<Map<String, dynamic>> startGame() {
    return _socket.startGame();
  }

  Future<Map<String, dynamic>> markReady() {
    return _socket.markReady();
  }

  Future<Map<String, dynamic>> sendClue(String text) {
    return _socket.sendClue(text);
  }

  Future<Map<String, dynamic>> submitAccusation(String targetId) {
    return _socket.submitAccusation(targetId);
  }

  Future<Map<String, dynamic>> guessWord(String word) {
    return _socket.guessWord(word);
  }
}
