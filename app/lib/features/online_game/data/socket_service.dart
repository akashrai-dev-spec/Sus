import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;
  String? _connectedUrl;
  String? _playerId;
  String? _resumeToken;

  final _roomStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _roleController = StreamController<Map<String, dynamic>>.broadcast();
  final _turnController = StreamController<Map<String, dynamic>>.broadcast();
  final _clueController = StreamController<Map<String, dynamic>>.broadcast();
  final _accusationController = StreamController<Map<String, dynamic>>.broadcast();
  final _endedController = StreamController<Map<String, dynamic>>.broadcast();
  final _kickedController = StreamController<Map<String, dynamic>>.broadcast();
  final _bannedController = StreamController<Map<String, dynamic>>.broadcast();
  final _abortedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _sessionInfoController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onRoomState => _roomStateController.stream;
  Stream<Map<String, dynamic>> get onRole => _roleController.stream;
  Stream<Map<String, dynamic>> get onTurn => _turnController.stream;
  Stream<Map<String, dynamic>> get onClue => _clueController.stream;
  Stream<Map<String, dynamic>> get onAccusation => _accusationController.stream;
  Stream<Map<String, dynamic>> get onEnded => _endedController.stream;
  Stream<Map<String, dynamic>> get onKicked => _kickedController.stream;
  Stream<Map<String, dynamic>> get onBanned => _bannedController.stream;
  Stream<Map<String, dynamic>> get onAborted => _abortedController.stream;
  Stream<bool> get onConnectionChanged => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onSessionInfo => _sessionInfoController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? get playerId => _playerId;
  String? get resumeToken => _resumeToken;

  void connect({
    required String serverUrl,
    String? resumeToken,
    required String name,
    required String color,
  }) {
    if (_socket != null && _connectedUrl == serverUrl && _socket!.connected) {
      return;
    }

    _socket?.dispose();
    _connectedUrl = serverUrl;

    final cleanUrl = serverUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = '$cleanUrl/game';

    _socket = io.io(
      uri,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({
            'protocolVersion': '1.0.0',
            if (resumeToken != null) 'resumeToken': resumeToken,
          })
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connection error to $uri: $err');
    });

    _socket!.onConnect((_) async {
      debugPrint('[Socket] Connected to $uri');
      _connectionStateController.add(true);
      await emitHello(name: name, color: color, resumeToken: resumeToken);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected from server');
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connection error: $err');
      _connectionStateController.add(false);
    });

    _socket!.on('room:state', (data) {
      if (data is Map) {
        _roomStateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('game:role', (data) {
      if (data is Map) {
        _roleController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('game:turn', (data) {
      if (data is Map) {
        _turnController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('game:clue', (data) {
      if (data is Map) {
        _clueController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('game:accusation', (data) {
      if (data is Map) {
        _accusationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('game:ended', (data) {
      if (data is Map) {
        _endedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('room:kicked', (data) {
      if (data is Map) {
        _kickedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('room:banned', (data) {
      if (data is Map) {
        _bannedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('game:aborted', (data) {
      if (data is Map) {
        _abortedController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  Future<Map<String, dynamic>> emitWithAck(String event, dynamic payload) {
    final completer = Completer<Map<String, dynamic>>();

    if (_socket == null || !_socket!.connected) {
      return Future.value({
        'ok': false,
        'code': 'NOT_CONNECTED',
        'message': 'Cannot communicate with server: offline.',
      });
    }

    _socket!.emitWithAck(event, payload, ack: (dynamic response) {
      if (response is Map) {
        completer.complete(Map<String, dynamic>.from(response));
      } else {
        completer.complete({'ok': true, 'data': response});
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => {
        'ok': false,
        'code': 'TIMEOUT',
        'message': 'Server request timed out. Please try again.',
      },
    );
  }

  Future<Map<String, dynamic>> emitHello({
    required String name,
    required String color,
    String? resumeToken,
  }) async {
    final res = await emitWithAck('session:hello', {
      'name': name,
      'color': color,
      if (resumeToken != null) 'resumeToken': resumeToken,
    });
    if (res['ok'] == true && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      _playerId = data['playerId'] as String?;
      _resumeToken = data['resumeToken'] as String?;
      _sessionInfoController.add(data);
    }
    return res;
  }

  Future<Map<String, dynamic>> listRooms() {
    return emitWithAck('rooms:list', {});
  }

  Future<Map<String, dynamic>> createRoom({
    required String name,
    required String pin,
    required Map<String, dynamic> settings,
  }) {
    return emitWithAck('rooms:create', {
      'name': name,
      'pin': pin,
      'settings': settings,
    });
  }

  Future<Map<String, dynamic>> joinRoom({
    required String roomId,
    required String pin,
  }) {
    return emitWithAck('rooms:join', {
      'roomId': roomId,
      'pin': pin,
    });
  }

  Future<Map<String, dynamic>> leaveRoom() {
    return emitWithAck('rooms:leave', {});
  }

  Future<Map<String, dynamic>> syncRoom([String? roomId]) {
    return emitWithAck('room:sync', {'roomId': roomId});
  }

  Future<Map<String, dynamic>> startGame() {
    return emitWithAck('game:start', {});
  }

  Future<Map<String, dynamic>> markReady() {
    return emitWithAck('game:ready', {});
  }

  Future<Map<String, dynamic>> sendClue(String text) {
    return emitWithAck('turn:clue', {'text': text});
  }

  Future<Map<String, dynamic>> submitAccusation(String targetId) {
    return emitWithAck('accuse:submit', {'targetId': targetId});
  }

  Future<Map<String, dynamic>> guessWord(String word) {
    return emitWithAck('imposter:guess', {'word': word});
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) {
    return emitWithAck('room:updateSettings', settings);
  }

  Future<Map<String, dynamic>> kickPlayer(String targetId) {
    return emitWithAck('room:kickPlayer', {'targetId': targetId});
  }

  Future<Map<String, dynamic>> banPlayer(String targetId) {
    return emitWithAck('room:banPlayer', {'targetId': targetId});
  }

  Future<Map<String, dynamic>> suggestRoomName([String? baseName]) {
    return emitWithAck('rooms:suggest-name', {'baseName': baseName});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _roomStateController.close();
    _roleController.close();
    _turnController.close();
    _clueController.close();
    _accusationController.close();
    _endedController.close();
    _kickedController.close();
    _bannedController.close();
    _abortedController.close();
    _connectionStateController.close();
    _sessionInfoController.close();
  }
}
