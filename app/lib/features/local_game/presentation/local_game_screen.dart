import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/platform/screen_keep_awake.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/content_column.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../core/widgets/player_tile.dart';
import '../../../core/widgets/role_card.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../../core/widgets/turn_indicator.dart';
import '../../../engine/models/accusation_result.dart';
import '../../../engine/models/game_phase.dart';
import '../../../engine/models/game_player.dart';
import '../../profile/presentation/profile_controller.dart';
import 'local_game_controller.dart';

class LocalGameScreen extends ConsumerStatefulWidget {
  const LocalGameScreen({super.key});

  @override
  ConsumerState<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends ConsumerState<LocalGameScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenKeepAwake.enable();
  }

  @override
  void dispose() {
    ScreenKeepAwake.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Hide card on background to prevent spoilers
      final progress = ref.read(localGameControllerProvider);
      if (progress != null && progress.isCardRevealedToPlayer) {
        ref.read(localGameControllerProvider.notifier).onNextPlayerHandover();
      }
    }
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
                'Leave this game?',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'You will return to the main menu and current progress will be lost.',
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
                      child: Text(
                        'Stay',
                        style: SusTypography.body.copyWith(
                          color: colors.bone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                      child: Text(
                        'Leave',
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

    if ((leave ?? false) && mounted) {
      context.go('/');
    }
  }

  Future<void> _showAccuseFlow() async {
    final progress = ref.read(localGameControllerProvider);
    if (progress == null) return;
    final gameState = progress.gameState;
    final isFinal = gameState.currentPhase is FinalVotePhase;
    final alive = gameState.alivePlayers;

    String? targetId;
    String? accuserId;

    if (isFinal) {
      targetId = await _showTargetPickerSheet(
        title: 'Final accusation',
        subtitle: 'Who does the group accuse? A wrong guess ends the game.',
        targets: alive,
      );
      if (targetId == null || !mounted) return;
    } else {
      final eligibleAccusers = alive.where((p) => !p.usedAccusation).toList();
      if (eligibleAccusers.isEmpty) {
        AppToast.show(context, 'No players have accusations left.');
        return;
      }

      accuserId = await _showAccuserPickerSheet(accusers: eligibleAccusers);
      if (accuserId == null || !mounted) return;

      final accuser = gameState.getPlayer(accuserId)!;
      final availableTargets = alive.where((p) => p.id != accuserId).toList();

      targetId = await _showTargetPickerSheet(
        title: '${accuser.name} accuses…',
        subtitle: 'Pick who you think is the imposter. They will reveal their role.',
        targets: availableTargets,
      );
      if (targetId == null || !mounted) return;
    }

    ref.read(localGameControllerProvider.notifier).accuse(
          accuserId: accuserId,
          targetId: targetId,
        );

    if (!mounted) return;
    await _showAccusationOutcomeSheet();

    if (mounted) {
      final state = ref.read(localGameControllerProvider)?.gameState;
      if (state?.currentPhase is EndedPhase) {
        context.go('/results');
      }
    }
  }

  Future<String?> _showAccuserPickerSheet({
    required List<GamePlayer> accusers,
  }) {
    return showModalBottomSheet<String>(
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
                'Who is accusing?',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'Each player gets one accusation per game.',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accusers.length,
                  itemBuilder: (context, i) {
                    final p = accusers[i];
                    return PlayerTile(
                      name: p.name,
                      colorHex: p.color,
                      onTap: () {
                        Navigator.of(ctx).pop(p.id);
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

  Future<String?> _showTargetPickerSheet({
    required String title,
    required String subtitle,
    required List<GamePlayer> targets,
  }) {
    return showModalBottomSheet<String>(
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
              Text(title, style: SusTypography.title.copyWith(color: colors.bone)),
              const SizedBox(height: 6),
              Text(subtitle, style: SusTypography.body.copyWith(color: colors.mute)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: targets.length,
                  itemBuilder: (context, i) {
                    final p = targets[i];
                    return PlayerTile(
                      name: p.name,
                      colorHex: p.color,
                      onTap: () {
                        Navigator.of(ctx).pop(p.id);
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

  Future<void> _showAccusationOutcomeSheet() {
    final progress = ref.read(localGameControllerProvider);
    if (progress == null) return Future.value();
    final res = progress.gameState.lastAccusationResult;
    if (res == null) return Future.value();

    final target = progress.gameState.getPlayer(res.targetId)!;
    final accuser = res.accuserId != null ? progress.gameState.getPlayer(res.accuserId!) : null;
    final isCaught = res.outcome == AccusationOutcome.caught;

    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
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
                accuser != null
                    ? '${accuser.name} accused ${target.name}'
                    : 'The group accused ${target.name}',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                'The game is paused. Role revealed:',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 18),
              if (res.roleReverse) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                isCaught ? 'Imposter!' : 'Normal player.',
                style: SusTypography.display.copyWith(
                  color: isCaught ? colors.win : colors.lose,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                res.roleReverse
                    ? 'Roles reversed! A new imposter has been chosen. Discussion restarts from ${accuser?.name ?? 'the accuser'}.'
                    : isCaught
                        ? '${target.name} was caught and is eliminated.'
                        : res.isFinalVote
                            ? 'The final accusation named the wrong player.'
                            : '${accuser?.name} has used up their accusation.',
                style: SusTypography.body.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.crimson,
                  minimumSize: const Size.fromHeight(52),
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
        );
      },
    );
  }

  Future<void> _showImposterGuessDialog() async {
    final progress = ref.read(localGameControllerProvider);
    if (progress == null) return;
    final alive = progress.gameState.alivePlayers;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        String selectedPlayerId = alive.first.id;
        final guessController = TextEditingController();

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colors = ctx.colors;
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Imposter guess',
                    style: SusTypography.title.copyWith(color: colors.bone),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only an imposter should try this. Pick your name and type the secret word.',
                    style: SusTypography.body.copyWith(color: colors.mute),
                  ),
                  const SizedBox(height: 16),
                  Text('Who is guessing?', style: SusTypography.caption.copyWith(color: colors.mute)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: colors.panel,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.line, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPlayerId,
                        isExpanded: true,
                        dropdownColor: colors.panel,
                        style: SusTypography.body.copyWith(color: colors.bone),
                        items: alive.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(p.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedPlayerId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Word guess', style: SusTypography.caption.copyWith(color: colors.mute)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: guessController,
                    style: SusTypography.body.copyWith(color: colors.bone),
                    decoration: const InputDecoration(hintText: 'Type your guess...'),
                  ),
                  const SizedBox(height: 22),
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
                          onPressed: () {
                            final guess = guessController.text.trim();
                            if (guess.isEmpty) return;

                            Navigator.of(sheetContext).pop({
                              'playerId': selectedPlayerId,
                              'word': guess,
                            });
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
      },
    );

    if (result != null && mounted) {
      final won = ref
          .read(localGameControllerProvider.notifier)
          .imposterGuess(
            playerId: result['playerId']!,
            word: result['word']!,
          );

      if (won) {
        context.go('/results');
      } else {
        AppToast.show(context, 'Not the word');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = ref.watch(localGameControllerProvider);
    final profile = ref.watch(userProfileProvider);

    if (progress == null) {
      return Scaffold(
        appBar: AppHeader(
          playerName: profile.name,
          playerColorHex: profile.color,
          onBack: _confirmLeaveGame,
        ),
        body: Center(
          child: CircularProgressIndicator(color: colors.crimson),
        ),
      );
    }

    final gameState = progress.gameState;
    final phase = gameState.currentPhase;

    return Scaffold(
      appBar: AppHeader(
        playerName: profile.name,
        playerColorHex: profile.color,
        onBack: _confirmLeaveGame,
      ),
      body: ContentColumn(
        child: phase is RoleRevealPhase
            ? _buildRoleRevealView(colors, progress)
            : _buildGameView(colors, progress),
      ),
    );
  }

  Widget _buildRoleRevealView(SusColors colors, LocalGameProgress progress) {
    final idx = progress.handoverPlayerIndex;
    final player = progress.gameState.players[idx];
    final isLast = idx >= progress.gameState.players.length - 1;

    if (!progress.isCardRevealedToPlayer) {
      // Step 1: Handover screen
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          PlayerAvatar(
            name: player.name,
            colorHex: player.color,
            size: 76,
          ),
          const SizedBox(height: 20),
          Text(
            'Pass the phone to ${player.name}',
            style: SusTypography.title.copyWith(color: colors.bone),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Only ${player.name} should look at the screen.\nPlayer ${idx + 1} of ${progress.gameState.players.length}.',
            style: SusTypography.body.copyWith(color: colors.mute),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              ref.read(localGameControllerProvider.notifier).onPlayerAcknowledgedHandover();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.crimson,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'I’m ${player.name}',
              style: SusTypography.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    // Step 2: RoleCard reveal
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${player.name}, your secret role',
          style: SusTypography.title.copyWith(color: colors.bone),
        ),
        const SizedBox(height: 6),
        Text(
          'Press and hold the card. Let go to hide it.',
          style: SusTypography.body.copyWith(color: colors.mute),
        ),
        const SizedBox(height: 24),
        RoleCard(
          isImposter: player.isImposter,
          category: progress.gameState.category,
          secretWord: player.isNormal ? progress.gameState.secretWord : null,
        ),
        const Spacer(),
        SwipeToConfirm(
          label: isLast ? 'Hide and start discussion' : 'Hide and pass it on',
          onConfirm: () {
            ref.read(localGameControllerProvider.notifier).onNextPlayerHandover();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGameView(SusColors colors, LocalGameProgress progress) {
    final gameState = progress.gameState;
    final phase = gameState.currentPhase;
    final isFinal = phase is FinalVotePhase;
    final isEnded = phase is EndedPhase;
    final currentSpeaker = gameState.currentSpeakerId;

    final String roundText;
    if (isFinal) {
      roundText = 'Final accusation';
    } else if (phase is DiscussionPhase) {
      roundText = 'Round ${phase.round} of ${gameState.settings.rounds}';
    } else if (isEnded) {
      roundText = 'Game over';
    } else {
      roundText = 'Discussion';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TurnIndicator(
          roundText: roundText,
          category: gameState.category,
        ),
        Text(
          isEnded
              ? 'The match has ended. Tap below to see results.'
              : isFinal
                  ? 'Discussion is over. Vote together, then accuse.'
                  : 'Speak out loud in this order. Describe the word without saying it.',
          style: SusTypography.body.copyWith(color: colors.mute),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: gameState.speakingOrder.length,
            itemBuilder: (context, i) {
              final pId = gameState.speakingOrder[i];
              final p = gameState.getPlayer(pId)!;
              final isSpeaking = !isFinal && !isEnded && pId == currentSpeaker;

              return PlayerTile(
                name: p.name,
                colorHex: p.color,
                isAlive: p.isAlive,
                isSpeaking: isSpeaking,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (isEnded) ...[
          SwipeToConfirm(
            label: 'View match results',
            onConfirm: () => context.go('/results'),
          ),
        ] else ...[
          if (!isFinal) ...[
            SwipeToConfirm(
              label: 'Next speaker',
              onConfirm: () {
                ref.read(localGameControllerProvider.notifier).nextSpeaker();
              },
            ),
            const SizedBox(height: 10),
          ],
          SwipeToConfirm(
            label: 'Accuse',
            onConfirm: _showAccuseFlow,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _showImposterGuessDialog,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: colors.line, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Imposter guess',
              style: SusTypography.body.copyWith(
                color: colors.bone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
