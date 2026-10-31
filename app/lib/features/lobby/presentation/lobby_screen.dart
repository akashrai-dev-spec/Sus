import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/content_column.dart';
import '../../../core/widgets/player_tile.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../online_game/presentation/online_game_controller.dart';
import '../../profile/presentation/profile_controller.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  void _confirmLeaveLobby() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1D1D1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave room?',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'You will return to the main menu.',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.line, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Stay', style: SusTypography.body.copyWith(color: colors.bone)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await ref.read(onlineGameControllerProvider.notifier).leaveRoom();
                        if (mounted) context.go('/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.crimson,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Leave', style: SusTypography.body.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final online = ref.watch(onlineGameControllerProvider);
    final profile = ref.watch(userProfileProvider);

    final room = online.roomState;
    if (room == null) {
      return Scaffold(
        appBar: AppHeader(
          playerName: profile.name,
          playerColorHex: profile.color,
          onBack: _confirmLeaveLobby,
        ),
        body: Center(
          child: CircularProgressIndicator(color: colors.crimson),
        ),
      );
    }

    // Auto-navigate if game transitioned to role reveal or discussion
    final phase = room['phase'] as String? ?? 'lobby';
    if (phase != 'lobby') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/online-game/${widget.roomId}');
        }
      });
    }

    final roomName = room['name'] as String? ?? 'Game Lobby';
    final players = (room['players'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final settings = Map<String, dynamic>.from(room['settings'] as Map? ?? {});
    final isHost = online.isHost;
    final playerCount = players.length;
    final maxPlayers = room['max'] as int? ?? 6;

    final impostersCount = (settings['imposters'] as int?) ?? 1;
    final roundsCount = (settings['rounds'] as int?) ?? 2;
    final guessCount = (settings['guessAttempts'] as int?) ?? 1;
    final categoryName = settings['category'] ?? 'Random';

    return Scaffold(
      appBar: AppHeader(
        playerName: profile.name,
        playerColorHex: profile.color,
        onBack: _confirmLeaveLobby,
      ),
      body: ContentColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roomName,
              style: SusTypography.title.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 4),
            Text(
              '$playerCount/$maxPlayers players · PIN ${room['pin'] ?? '••••'}',
              style: SusTypography.body.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 12),

            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(colors, '$impostersCount imposter${impostersCount > 1 ? 's' : ''}'),
                _buildChip(colors, '$roundsCount round${roundsCount > 1 ? 's' : ''}'),
                _buildChip(colors, '$guessCount guess${guessCount > 1 ? 'es' : ''}'),
                _buildChip(colors, categoryName.toString()),
              ],
            ),
            const SizedBox(height: 20),

            // Players list
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, i) {
                  final p = players[i];
                  final pId = p['id'] as String;
                  final pName = p['name'] as String;
                  final pColor = p['color'] as String;
                  final pIsHost = p['isHost'] as bool? ?? false;
                  final isYou = pId == online.playerId;

                  return PlayerTile(
                    name: pName,
                    colorHex: pColor,
                    isHost: pIsHost,
                    isYou: isYou,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            if (isHost) ...[
              SwipeToConfirm(
                label: playerCount < 3 ? 'Need 3 players to start' : 'Start game',
                enabled: playerCount >= 3,
                onConfirm: () async {
                  final res = await ref.read(onlineGameControllerProvider.notifier).startGame();
                  if (res['ok'] != true && mounted) {
                    AppToast.show(
                      context,
                      (res['message'] as String?) ?? 'Cannot start game',
                    );
                  }
                },
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Waiting for the host to start…',
                    style: SusTypography.body.copyWith(color: colors.mute),
                  ),
                ),
              ),
            ],
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
