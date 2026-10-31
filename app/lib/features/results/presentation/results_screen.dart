import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/content_column.dart';
import '../../../core/widgets/player_tile.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../../engine/models/game_phase.dart';
import '../../local_game/presentation/local_game_controller.dart';
import '../../online_game/presentation/online_game_controller.dart';
import '../../profile/presentation/profile_controller.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(userProfileProvider);
    final localProgress = ref.watch(localGameControllerProvider);
    final onlineState = ref.watch(onlineGameControllerProvider);

    final isLocal = localProgress != null;

    final String winner;
    final String reason;
    final String secretWord;
    final String category;
    final List<Map<String, dynamic>> players;

    if (isLocal) {
      final gameState = localProgress.gameState;
      final ended = gameState.currentPhase is EndedPhase
          ? gameState.currentPhase as EndedPhase
          : null;

      winner = ended?.winner ?? 'normal';
      reason = ended?.reason ?? 'Game over';
      secretWord = gameState.secretWord;
      category = gameState.category;
      players = gameState.players.map((p) {
        return {
          'id': p.id,
          'name': p.name,
          'color': p.color,
          'role': p.isImposter ? 'imposter' : 'normal',
        };
      }).toList();
    } else {
      final ended = onlineState.gameEndedData ?? {};
      final room = onlineState.roomState ?? {};
      winner = ended['winner'] as String? ?? 'normal';
      reason = ended['reason'] as String? ?? 'Game over';
      secretWord = ended['secretWord'] as String? ?? 'Secret';
      category = ended['category'] as String? ?? 'General';

      final allRoles = Map<String, dynamic>.from(ended['allRoles'] as Map? ?? {});
      final rawPlayers = room['players'] as List? ?? [];

      players = rawPlayers.map((e) {
        final p = Map<String, dynamic>.from(e as Map);
        return {
          'id': p['id'],
          'name': p['name'],
          'color': p['color'],
          'role': allRoles[p['id']] ?? p['role'] ?? 'normal',
        };
      }).toList();
    }

    final isNormWin = winner == 'normal';
    final isUserImposter = isLocal ? false : onlineState.isImposter;
    final didUserWin = isLocal ? isNormWin : (isNormWin != isUserImposter);

    final headline = isLocal
        ? (isNormWin ? 'Players win' : 'Imposter wins')
        : (didUserWin ? 'You win' : 'You lose');

    return Scaffold(
      appBar: AppHeader(
        playerName: profile.name,
        playerColorHex: profile.color,
        showBack: false,
      ),
      body: ContentColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNormWin ? 'Normal players win' : 'The imposter wins',
              style: SusTypography.caption.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 4),
            Text(
              headline,
              style: SusTypography.display.copyWith(
                color: didUserWin ? colors.win : colors.lose,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reason,
              style: SusTypography.body.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 16),

            // Chips: Word & Category
            Wrap(
              spacing: 8,
              children: [
                _buildChip(colors, 'Word: $secretWord'),
                _buildChip(colors, category),
              ],
            ),
            const SizedBox(height: 20),

            // All player roles revealed
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, i) {
                  final p = players[i];
                  final isImp = p['role'] == 'imposter';

                  return PlayerTile(
                    name: p['name'] as String,
                    colorHex: p['color'] as String,
                    trailingPill: isImp ? 'Imposter' : 'Normal',
                    trailingPillColor: isImp ? colors.crimson : Colors.black38,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Play again SwipeToConfirm
            SwipeToConfirm(
              label: 'Play again',
              onConfirm: () {
                if (isLocal) {
                  ref.read(localGameControllerProvider.notifier).restartGame();
                  context.go('/local-game');
                } else {
                  context.go('/lobby/${onlineState.roomState?['id']}');
                }
              },
            ),
            const SizedBox(height: 10),

            // Home button
            ElevatedButton(
              onPressed: () {
                if (!isLocal) {
                  ref.read(onlineGameControllerProvider.notifier).leaveRoom();
                }
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.ash,
                foregroundColor: const Color(0xFF111111),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Home',
                style: SusTypography.body.copyWith(
                  color: const Color(0xFF111111),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(SusColors colors, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.line, width: 1),
      ),
      child: Text(
        label,
        style: SusTypography.caption.copyWith(
          color: colors.bone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
