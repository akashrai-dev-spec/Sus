import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/clue_bubble.dart';
import '../../../core/widgets/content_column.dart';
import '../../../core/widgets/player_tile.dart';
import '../../../core/widgets/role_card.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../../core/widgets/turn_indicator.dart';
import '../../profile/presentation/profile_controller.dart';
import 'online_game_controller.dart';

class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  final TextEditingController _clueController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasSeenRole = false;
  String? _lastShownAccusationKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(onlineGameControllerProvider.notifier).syncRoom(widget.roomId);
      }
    });
  }

  @override
  void dispose() {
    _clueController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmLeaveGame() async {
    final leave = await showModalBottomSheet<bool>(
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
                'Leave match?',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'You will exit this game and return to the home screen.',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
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
                      onPressed: () => Navigator.of(ctx).pop(true),
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

    if ((leave ?? false) && mounted) {
      await ref.read(onlineGameControllerProvider.notifier).leaveRoom();
      if (mounted) context.go('/');
    }
  }

  void _showAccusationOutcomeDialog(
    SusColors colors,
    Map<String, dynamic> res,
    List<Map<String, dynamic>> players,
  ) {
    final targetId = res['targetId'] ?? res['accusedId'];
    final accuserId = res['accuserId'];
    final target = players.firstWhere(
      (p) => p['id'] == targetId,
      orElse: () => {'name': 'Player'},
    );
    final accuser = accuserId != null
        ? players.firstWhere(
            (p) => p['id'] == accuserId,
            orElse: () => {'name': 'Player'},
          )
        : null;

    final isHit = res['outcome'] == 'caught' || res['revealedRole'] == 'imposter';
    final roleReverse = res['roleReverse'] == true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1D1D1D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: roleReverse ? colors.crimson : colors.line,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (roleReverse) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.crimson.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: colors.crimson),
                    ),
                    child: Text(
                      'ROLE REVERSE!',
                      style: SusTypography.caption.copyWith(
                        color: colors.crimsonBright,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Role Revealed',
                  style: SusTypography.caption.copyWith(
                    color: colors.mute,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  target['name'] as String? ?? 'Player',
                  style: SusTypography.title.copyWith(
                    color: colors.bone,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isHit
                        ? colors.crimson.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isHit ? colors.crimson : colors.line,
                    ),
                  ),
                  child: Text(
                    isHit ? 'IMPOSTER! (Eliminated)' : 'NORMAL PLAYER (Innocent!)',
                    style: SusTypography.title.copyWith(
                      color: isHit ? colors.crimsonBright : colors.bone,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  roleReverse
                      ? 'Roles have reversed and a new imposter has been chosen. Discussion restarts from the accuser.'
                      : isHit
                          ? '${target['name']} was caught and eliminated.'
                          : '${accuser?['name'] ?? 'The accuser'} accused an innocent player.',
                  style: SusTypography.body.copyWith(
                    color: colors.mute,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref.read(onlineGameControllerProvider.notifier).clearAccusation();
                    if (roleReverse) {
                      _showRoleReversedDialog(colors);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.crimson,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: SusTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRoleReversedDialog(SusColors colors) {
    final online = ref.read(onlineGameControllerProvider);
    final isImposter = online.isImposter;
    final secretWord = online.mySecretWord ?? 'Secret';
    final category = online.myCategory ?? 'General';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1D1D1D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.crimson, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.crimson.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: colors.crimson),
                  ),
                  child: Text(
                    'ROLE REVERSAL APPLIED',
                    style: SusTypography.caption.copyWith(
                      color: colors.crimsonBright,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your New Role',
                  style: SusTypography.caption.copyWith(
                    color: colors.mute,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isImposter ? 'You are now the IMPOSTER' : 'Innocent Player',
                  style: SusTypography.title.copyWith(
                    color: colors.bone,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isImposter
                        ? colors.crimson.withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isImposter ? colors.crimson : const Color(0xFF10B981),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (isImposter) ...[
                        Text(
                          'Category: $category',
                          style: SusTypography.title.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You do not know the secret word. Blend in with believable clues and guess the secret word to win!',
                          style: SusTypography.caption.copyWith(
                            color: colors.mute,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          'Secret Word',
                          style: SusTypography.caption.copyWith(
                            color: colors.mute,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          secretWord,
                          style: SusTypography.display.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Category: $category',
                          style: SusTypography.body.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Give subtle clues without saying the word!',
                          style: SusTypography.caption.copyWith(
                            color: colors.mute,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.crimson,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Enter Discussion Box',
                    style: SusTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPeekDialog(SusColors colors, OnlineState online) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: RoleCard(
            isImposter: online.isImposter,
            category: online.myCategory ?? 'General',
            secretWord: online.mySecretWord,
          ),
        );
      },
    );
  }

  void _showAccuseSheet(List<Map<String, dynamic>> aliveTargets) {
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
                'Accuse a player',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'The game pauses and their role will be revealed.',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: aliveTargets.length,
                  itemBuilder: (context, i) {
                    final t = aliveTargets[i];
                    return PlayerTile(
                      name: t['name'] as String,
                      colorHex: t['color'] as String,
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        final controller = ref.read(onlineGameControllerProvider.notifier);
                        final res = await controller.submitAccusation(t['id'] as String);
                        if (res['ok'] != true && mounted) {
                          AppToast.show(
                            context,
                            (res['message'] as String?) ?? 'Accusation failed',
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: colors.line, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Cancel', style: SusTypography.body.copyWith(color: colors.bone)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGuessDialog() {
    final guessController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guess the word',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'Type your guess. A correct guess wins the game immediately!',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: guessController,
                autofocus: true,
                style: SusTypography.body.copyWith(color: colors.bone),
                decoration: const InputDecoration(hintText: 'Enter your guess...'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.line, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: SusTypography.body.copyWith(color: colors.bone)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final word = guessController.text.trim();
                        if (word.isEmpty) return;

                        Navigator.of(sheetContext).pop();
                        final controller = ref.read(onlineGameControllerProvider.notifier);
                        final res = await controller.guessWord(word);

                        if (res['ok'] == true && res['data']?['correct'] == false && mounted) {
                          AppToast.show(context, 'Not the word');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.crimson,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Guess',
                        style: SusTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Future<void> _sendClue() async {
    final text = _clueController.text.trim();
    if (text.isEmpty) return;

    _clueController.clear();
    final controller = ref.read(onlineGameControllerProvider.notifier);
    final res = await controller.sendClue(text);

    if (res['ok'] != true && mounted) {
      AppToast.show(
        context,
        (res['message'] as String?) ?? 'Cannot send clue',
      );
    } else {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final online = ref.watch(onlineGameControllerProvider);
    final profile = ref.watch(userProfileProvider);

    final room = online.roomState;
    if (room == null) {
      if (online.notificationMessage != null) {
        final msg = online.notificationMessage!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppToast.show(context, msg);
            ref.read(onlineGameControllerProvider.notifier).clearNotification();
            context.go('/rooms');
          }
        });
      }
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _confirmLeaveGame();
        },
        child: Scaffold(
          appBar: AppHeader(
            playerName: profile.name,
            playerColorHex: profile.color,
            onBack: _confirmLeaveGame,
          ),
          body: Center(child: CircularProgressIndicator(color: colors.crimson)),
        ),
      );
    }

    if (online.notificationMessage != null) {
      final msg = online.notificationMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppToast.show(context, msg);
          ref.read(onlineGameControllerProvider.notifier).clearNotification();
        }
      });
    }

    final phase = room['phase'] as String? ?? 'roleReveal';

    // Return to lobby if game was aborted due to lack of players
    if (phase == 'lobby') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppToast.show(
            context,
            'Not enough players to continue. Returned to lobby.',
          );
          context.go('/lobby/${widget.roomId}');
        }
      });
    }

    // End of game navigation
    if (phase == 'ended') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/results');
      });
    }

    final players = (room['players'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final myPlayerId = online.playerId ??
        players.firstWhere(
          (p) => p['name'] == profile.name,
          orElse: () => <String, dynamic>{},
        )['id'] as String?;

    final myPlayer = players.firstWhere(
      (p) => (myPlayerId != null && p['id'] == myPlayerId) || p['name'] == profile.name,
      orElse: () => <String, dynamic>{},
    );

    // Accusation popup
    final latestAccusation = online.latestAccusation ??
        (room['lastAccusation'] is Map
            ? Map<String, dynamic>.from(room['lastAccusation'] as Map)
            : null);
    if (latestAccusation != null) {
      final accKey =
          '${latestAccusation['accuserId']}-${latestAccusation['targetId'] ?? latestAccusation['accusedId']}-${latestAccusation['outcome']}-${latestAccusation['roleReverse']}';
      if (_lastShownAccusationKey != accKey) {
        _lastShownAccusationKey = accKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showAccusationOutcomeDialog(colors, latestAccusation, players);
          }
        });
      }
    }

    // Role reveal view
    if (phase == 'roleReveal') {
      final isMyReady = (myPlayer['isReady'] as bool? ?? false) || _hasSeenRole;
      final readyPlayers = players.where((p) => p['isReady'] == true).toList();
      final waitingPlayers = players.where((p) => p['isReady'] != true).toList();

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _confirmLeaveGame();
        },
        child: Scaffold(
          appBar: AppHeader(
            playerName: profile.name,
            playerColorHex: profile.color,
            onBack: _confirmLeaveGame,
          ),
          body: ContentColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your secret role',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'Press and hold the card. Let go to hide it.',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 24),
              RoleCard(
                isImposter: online.isImposter,
                category: online.myCategory ?? 'General',
                secretWord: online.mySecretWord,
              ),
              const Spacer(),
              if (isMyReady) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'You have confirmed your role',
                            style: SusTypography.body.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        waitingPlayers.isEmpty
                            ? 'Everyone is ready! Starting discussion...'
                            : 'Waiting for ${waitingPlayers.map((p) => p['name']).join(', ')} to confirm...',
                        style: SusTypography.body.copyWith(
                          color: colors.bone,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${readyPlayers.length} of ${players.length} players ready. You can still hold above to peek.',
                        style: SusTypography.caption.copyWith(color: colors.mute),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: players.map((p) {
                          final isPReady = p['isReady'] as bool? ?? false;
                          final pName = p['name'] as String? ?? 'Player';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPReady
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : colors.ink,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isPReady
                                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                    : colors.line,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  pName,
                                  style: SusTypography.caption.copyWith(
                                    color: isPReady ? colors.bone : colors.mute,
                                    fontWeight: isPReady ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (isPReady)
                                  const Icon(Icons.check, size: 14, color: Color(0xFF10B981))
                                else
                                  Text(
                                    'Waiting',
                                    style: SusTypography.caption.copyWith(
                                      color: const Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (readyPlayers.isNotEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${readyPlayers.length}/${players.length} players ready · Waiting for you',
                        style: SusTypography.caption.copyWith(
                          color: colors.mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                SwipeToConfirm(
                  label: 'I’ve seen it',
                  onConfirm: () async {
                    setState(() => _hasSeenRole = true);
                    await ref.read(onlineGameControllerProvider.notifier).markReady();
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

    // Active discussion / accusation view
    final currentTurn = room['currentTurn'] as Map<String, dynamic>?;
    final speakerId = currentTurn?['speakerId'] as String?;
    final roundNumber = currentTurn?['round'] ?? 1;
    final settings = Map<String, dynamic>.from(room['settings'] as Map? ?? {});
    final totalRounds = settings['rounds'] ?? 2;
    final isFinalVote = room['isFinalVote'] as bool? ?? false;

    final isAlive = myPlayer['isAlive'] as bool? ?? true;
    final usedAccusation = myPlayer['usedAccusation'] as bool? ?? false;
    final isMyTurn = (speakerId != null && (speakerId == myPlayerId || speakerId == myPlayer['id'])) && isAlive;

    final speakerPlayer = players.firstWhere(
      (p) => p['id'] == speakerId,
      orElse: () => {'name': 'Someone'},
    );

    final roundText = isFinalVote ? 'Final accusation' : 'Round $roundNumber of $totalRounds';
    final categoryName = online.myCategory ?? settings['category'] ?? 'General';

    final aliveTargets = players
        .where((p) => p['id'] != (myPlayerId ?? myPlayer['id']) && p['isAlive'] == true)
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLeaveGame();
      },
      child: Scaffold(
        appBar: AppHeader(
          playerName: profile.name,
          playerColorHex: profile.color,
          onBack: _confirmLeaveGame,
        ),
        body: ContentColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            TurnIndicator(
              roundText: roundText,
              category: categoryName.toString(),
              trailing: OutlinedButton(
                onPressed: () => _showPeekDialog(colors, online),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: BorderSide(color: colors.line, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded, size: 14, color: colors.mute),
                    const SizedBox(width: 4),
                    Text(
                      'Peek role',
                      style: SusTypography.caption.copyWith(
                        color: colors.mute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chips of players
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: players.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final p = players[i];
                  final isPAlive = p['isAlive'] as bool? ?? true;
                  final isSpeaking = p['id'] == speakerId;
                  final hasGivenClue = online.liveClues.any((c) => c['playerId'] == p['id']);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.panel,
                      borderRadius: BorderRadius.circular(99),
                      border: isSpeaking
                          ? Border.all(color: colors.crimsonBright, width: 2)
                          : Border.all(color: colors.line, width: 1),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p['name'].toString().split(' ')[0],
                            style: SusTypography.caption.copyWith(
                              color: isPAlive ? colors.bone : colors.mute,
                              fontWeight: isSpeaking ? FontWeight.w700 : FontWeight.w500,
                              decoration: isPAlive ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          if (isSpeaking) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.crimson,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Speaking',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ] else if (hasGivenClue) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Imposter guessing status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colors.panel.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      online.isImposter
                          ? 'You are the Imposter: You can guess the secret word anytime below to win immediately.'
                          : 'Imposter Guessing: The imposter can submit a word guess at any time to win.',
                      style: SusTypography.caption.copyWith(
                        color: colors.mute,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Clue Log
            Expanded(
              child: online.liveClues.isEmpty
                  ? Center(
                      child: Text(
                        'Nobody has spoken yet.',
                        style: SusTypography.body.copyWith(color: colors.mute),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: online.liveClues.length,
                      itemBuilder: (context, index) {
                        final clue = online.liveClues[index];
                        final sender = players.firstWhere(
                          (p) => p['id'] == clue['playerId'],
                          orElse: () => {'name': 'Player', 'color': '#9A0F28'},
                        );

                        return ClueBubble(
                          playerName: sender['name'] as String,
                          playerColorHex: sender['color'] as String,
                          text: clue['text'] as String,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),

            // Turn status prompt
            Text(
              isFinalVote
                  ? 'Time’s up. Make your final accusation.'
                  : !isAlive
                      ? 'You were caught. Watching ${speakerPlayer['name']}…'
                      : isMyTurn
                          ? 'Your turn! Give a clue OR accuse a player.'
                          : '${speakerPlayer['name']} is speaking…',
              style: SusTypography.body.copyWith(
                color: isMyTurn ? colors.crimsonBright : colors.bone,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Clue input if my turn
            if (isMyTurn) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _clueController,
                      maxLength: 60,
                      style: SusTypography.body.copyWith(color: colors.bone),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: 'Describe the word…',
                      ),
                      onSubmitted: (_) => _sendClue(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendClue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.crimson,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Send', style: SusTypography.body.copyWith(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (isFinalVote || !usedAccusation) ? () => _showAccuseSheet(aliveTargets) : null,
                icon: const Icon(Icons.gavel_rounded, size: 18),
                label: const Text('Or Accuse Player on Your Turn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: colors.crimsonBright,
                  side: BorderSide(color: colors.crimson.withValues(alpha: 0.6), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Action buttons: Accuse & Guess Word
            SwipeToConfirm(
              label: usedAccusation && !isFinalVote
                  ? 'Accusation used'
                  : (isMyTurn ? 'Swipe to Accuse Player' : 'Accuse'),
              enabled: isAlive && (isFinalVote || !usedAccusation),
              onConfirm: () => _showAccuseSheet(aliveTargets),
            ),
            if (online.isImposter && isAlive) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showGuessDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.ash,
                  foregroundColor: const Color(0xFF111111),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Guess word',
                  style: SusTypography.body.copyWith(
                    color: const Color(0xFF111111),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],
        ),
      ),
    ),
  );
}
}
