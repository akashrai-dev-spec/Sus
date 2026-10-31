import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sus/core/theme/app_theme.dart';
import 'package:sus/core/widgets/role_card.dart';
import 'package:sus/engine/game_engine.dart';
import 'package:sus/engine/models/game_player.dart';
import 'package:sus/engine/models/game_settings.dart';
import 'package:sus/features/create_game/presentation/create_game_screen.dart';
import 'package:sus/features/home/presentation/home_screen.dart';
import 'package:sus/features/local_game/presentation/local_game_controller.dart';
import 'package:sus/features/local_game/presentation/local_game_screen.dart';
import 'package:sus/features/mode/presentation/mode_screen.dart';
import 'package:sus/features/online_game/data/socket_service.dart';
import 'package:sus/features/online_game/presentation/online_game_controller.dart';
import 'package:sus/features/profile/data/profile_repository.dart';
import 'package:sus/features/profile/presentation/profile_controller.dart';
import 'package:sus/features/profile/presentation/profile_screen.dart';
import 'package:sus/features/results/presentation/results_screen.dart';
import 'package:sus/features/rules/presentation/rules_screen.dart';
import 'package:sus/features/rooms/presentation/rooms_screen.dart';

class MockSocketService extends SocketService {
  @override
  void connect({
    required String serverUrl,
    String? resumeToken,
    required String name,
    required String color,
  }) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    Directory('../docs/screenshots').createSync(recursive: true);
  });

  Future<void> renderAndSave(
    WidgetTester tester, {
    required Widget screen,
    required String filename,
    List<Override>? overrides,
  }) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(430 * 2, 932 * 2);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...?overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: screen,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../docs/screenshots/$filename').writeAsBytesSync(byteData!.buffer.asUint8List());
    });
  }

  testWidgets('01_home_screen', (tester) async {
    await renderAndSave(tester, screen: const HomeScreen(), filename: 'home_screen.png');
  });

  testWidgets('02_mode_screen', (tester) async {
    await renderAndSave(tester, screen: const ModeScreen(), filename: 'mode_screen.png');
  });

  testWidgets('03_rooms_screen', (tester) async {
    await renderAndSave(tester, screen: const RoomsScreen(), filename: 'rooms_screen.png');
  });

  testWidgets('04_create_game_screen', (tester) async {
    await renderAndSave(tester, screen: const CreateGameScreen(), filename: 'create_game_screen.png');
  });

  testWidgets('05_profile_screen', (tester) async {
    await renderAndSave(tester, screen: const ProfileScreen(), filename: 'profile_screen.png');
  });

  testWidgets('06_rules_screen', (tester) async {
    await renderAndSave(tester, screen: const RulesScreen(), filename: 'rules_screen.png');
  });

  testWidgets('07_role_reveal_screen', (tester) async {
    await renderAndSave(
      tester,
      screen: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: RoleCard(
            isImposter: false,
            category: 'Objects & Food',
            secretWord: 'Pineapple',
          ),
        ),
      ),
      filename: 'role_reveal_screen.png',
    );
  });

  testWidgets('08_local_game_screen', (tester) async {
    final players = [
      const GamePlayer(id: '1', name: 'Sneaky Otter', role: PlayerRole.normal),
      const GamePlayer(id: '2', name: 'Quiet Fox', role: PlayerRole.imposter),
      const GamePlayer(id: '3', name: 'Sleepy Yak', role: PlayerRole.normal),
    ];
    final gameState = GameEngine.startGame(
      players: players,
      settings: const GameSettings(category: 'Animals'),
      secretWord: 'Panda',
      category: 'Animals',
      customOrder: ['1', '2', '3'],
      customImposterIds: ['2'],
    );
    final discState = GameEngine.startDiscussion(gameState);

    await renderAndSave(
      tester,
      screen: const LocalGameScreen(),
      filename: 'local_game_screen.png',
      overrides: [
        localGameControllerProvider.overrideWith(
          (ref) => LocalGameNotifier()
            ..state = LocalGameProgress(
              gameState: discState,
              handoverPlayerIndex: 3,
              isCardRevealedToPlayer: false,
            ),
        ),
      ],
    );
  });

  testWidgets('09_results_screen', (tester) async {
    final players = [
      const GamePlayer(id: '1', name: 'Sneaky Otter', role: PlayerRole.normal),
      const GamePlayer(id: '2', name: 'Quiet Fox', role: PlayerRole.imposter),
      const GamePlayer(id: '3', name: 'Sleepy Yak', role: PlayerRole.normal),
    ];
    final gameState = GameEngine.startGame(
      players: players,
      settings: const GameSettings(category: 'Animals'),
      secretWord: 'Panda',
      category: 'Animals',
      customOrder: ['1', '2', '3'],
      customImposterIds: ['2'],
    );
    final discState = GameEngine.startDiscussion(gameState);
    final endedState = GameEngine.submitAccusation(discState, accuserId: '1', targetId: '2');
    final resolvedEnded = GameEngine.resolveAccusation(endedState);

    await renderAndSave(
      tester,
      screen: const ResultsScreen(),
      filename: 'results_screen.png',
      overrides: [
        onlineGameControllerProvider.overrideWith(
          (ref) => OnlineGameNotifier(
            MockSocketService(),
            const UserProfile(name: 'Sneaky Otter', color: '#9A0F28'),
          )..state = const OnlineState(),
        ),
        localGameControllerProvider.overrideWith(
          (ref) => LocalGameNotifier()
            ..state = LocalGameProgress(
              gameState: resolvedEnded,
              handoverPlayerIndex: 3,
              isCardRevealedToPlayer: false,
            ),
        ),
      ],
    );
  });
}
