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
      return Scaffold(
        appBar: AppHeader(
          playerName: profile.name,
          playerColorHex: profile.color,
        ),
        body: Center(child: CircularProgressIndicator(color: colors.crimson)),
      );
    }

    final phase = room['phase'] as String? ?? 'roleReveal';

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

    // Role reveal view
    if (phase == 'roleReveal') {
      final isMyReady = (myPlayer['isReady'] as bool? ?? false) || _hasSeenRole;
      final readyPlayers = players.where((p) => p['isReady'] == true).toList();
      final waitingPlayers = players.where((p) => p['isReady'] != true).toList();

      return Scaffold(
        appBar: AppHeader(
          playerName: profile.name,
          playerColorHex: profile.color,
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

    return Scaffold(
      appBar: AppHeader(
        playerName: profile.name,
        playerColorHex: profile.color,
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
                child: Text(
                  'Hold: my role',
                  style: SusTypography.caption.copyWith(
                    color: colors.mute,
                    fontWeight: FontWeight.w600,
                  ),
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
                      child: Text(
                        p['name'].toString().split(' ')[0],
                        style: SusTypography.caption.copyWith(
                          color: isPAlive ? colors.bone : colors.mute,
                          fontWeight: isSpeaking ? FontWeight.w700 : FontWeight.w500,
                          decoration: isPAlive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

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
                          ? 'Your turn. Give a clue.'
                          : '${speakerPlayer['name']} is speaking…',
              style: SusTypography.body.copyWith(
                color: colors.bone,
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
            ],

            // Action buttons: Accuse & Guess Word
            SwipeToConfirm(
              label: usedAccusation && !isFinalVote ? 'Accusation used' : 'Accuse',
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
    );
  }
}
