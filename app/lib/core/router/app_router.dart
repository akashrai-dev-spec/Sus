import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/create_game/presentation/create_game_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/legal/presentation/legal_screens.dart';
import '../../features/lobby/presentation/lobby_screen.dart';
import '../../features/local_game/presentation/local_game_screen.dart';
import '../../features/mode/presentation/mode_screen.dart';
import '../../features/online_game/presentation/online_game_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/results/presentation/results_screen.dart';
import '../../features/rules/presentation/rules_screen.dart';
import '../../features/rooms/presentation/rooms_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/mode',
        builder: (context, state) => const ModeScreen(),
      ),
      GoRoute(
        path: '/rooms',
        builder: (context, state) => const RoomsScreen(),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreateGameScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/rules',
        builder: (context, state) => const RulesScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalNoticeScreen(),
      ),
      GoRoute(
        path: '/lobby/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return LobbyScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/online-game/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return OnlineGameScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/local-game',
        builder: (context, state) => const LocalGameScreen(),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const ResultsScreen(),
      ),
    ],
  );
});
