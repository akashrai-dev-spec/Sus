import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/content_column.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../local_game/presentation/local_game_controller.dart';
import '../../online_game/presentation/online_game_controller.dart';
import '../../profile/presentation/profile_controller.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  String _mode = 'Online'; // 'Online' or 'Local'

  // Online fields
  late TextEditingController _roomNameController;
  late TextEditingController _pinController;
  int _maxPlayers = 6;
  int _imposters = 1;
  int _rounds = 2;
  int _guessAttempts = 1;
  String _category = 'Random';

  // Local fields
  List<TextEditingController> _localNameControllers = [];

  final List<String> _categories = [
    'Random',
    'Objects & Food',
    'Famous people',
    'Animals',
    'Places',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _roomNameController = TextEditingController(text: '${profile.name}’s room');
    final initialPin = (1000 + math.Random().nextInt(9000)).toString();
    _pinController = TextEditingController(text: initialPin);

    _localNameControllers = profile.lastLocalNames
        .map((name) => TextEditingController(text: name))
        .toList();

    while (_localNameControllers.length < 3) {
      _localNameControllers.add(
        TextEditingController(text: 'Player ${_localNameControllers.length + 1}'),
      );
    }
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _pinController.dispose();
    for (final c in _localNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addLocalPlayer() {
    if (_localNameControllers.length >= 12) return;
    setState(() {
      _localNameControllers.add(
        TextEditingController(text: 'Player ${_localNameControllers.length + 1}'),
      );
    });
  }

  void _removeLocalPlayer(int index) {
    if (_localNameControllers.length <= 3) return;
    setState(() {
      final removed = _localNameControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _handleCreateOnline() async {
    final name = _roomNameController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty) {
      AppToast.show(context, 'Please enter a room name');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      AppToast.show(context, 'PIN must be exactly 4 digits');
      return;
    }

    final controller = ref.read(onlineGameControllerProvider.notifier);
    final res = await controller.createRoom(
      name: name,
      pin: pin,
      settings: {
        'maxPlayers': _maxPlayers,
        'imposters': _imposters,
        'rounds': _rounds,
        'guessAttempts': _guessAttempts,
        'category': _category,
      },
    );

    if (res['ok'] == true && res['data'] != null) {
      final roomId = res['data']['id'] as String;
      if (mounted) {
        context.push('/lobby/$roomId');
      }
    } else {
      if (mounted) {
        AppToast.show(context, (res['message'] as String?) ?? 'Failed to create room');
      }
    }
  }

  void _handleStartLocal() {
    final names = _localNameControllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.length < 3) {
      AppToast.show(context, 'Add at least 3 player names');
      return;
    }

    // Persist local names
    ref.read(userProfileProvider.notifier).updateLastLocalNames(names);

    final localController = ref.read(localGameControllerProvider.notifier);
    localController.startLocalGame(
      playerNames: names,
      imposters: _imposters,
      rounds: _rounds,
      guessAttempts: _guessAttempts,
      category: _category,
    );

    context.push('/local-game');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppHeader(
        playerName: profile.name,
        playerColorHex: profile.color,
      ),
      body: ContentColumn(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a game',
                style: SusTypography.title.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 16),

              // Segmented control: Online | Local
              Text(
                'Game type',
                style: SusTypography.caption.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 6),
              SegmentedChoice<String>(
                options: const ['Online', 'Local'],
                selected: _mode,
                onChanged: (val) => setState(() => _mode = val),
              ),
              const SizedBox(height: 6),
              Text(
                _mode == 'Online'
                    ? 'Host a room on the server. Friends join from their own devices with the PIN.'
                    : 'Pass-and-play on one device. No internet required.',
                style: SusTypography.caption.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 20),

              if (_mode == 'Online') ..._buildOnlineFields(colors) else ..._buildLocalFields(colors),

              const SizedBox(height: 20),

              // Imposters
              Text(
                'Imposters',
                style: SusTypography.caption.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 6),
              SegmentedChoice<int>(
                options: const [1, 2, 3],
                selected: _imposters,
                onChanged: (val) => setState(() => _imposters = val),
              ),
              const SizedBox(height: 16),

              // Discussion rounds
              Text(
                'Discussion rounds',
                style: SusTypography.caption.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 6),
              SegmentedChoice<int>(
                options: const [1, 2, 3],
                selected: _rounds,
                onChanged: (val) => setState(() => _rounds = val),
              ),
              const SizedBox(height: 16),

              // Guess attempts
              Text(
                'Guess attempts for the imposter',
                style: SusTypography.caption.copyWith(color: colors.mute),
              ),
              const SizedBox(height: 6),
              SegmentedChoice<int>(
                options: const [1, 2],
                selected: _guessAttempts,
                onChanged: (val) => setState(() => _guessAttempts = val),
              ),
              const SizedBox(height: 16),

              // Secret word category
              Text(
                'Secret word category',
                style: SusTypography.caption.copyWith(color: colors.mute),
              ),
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
                    value: _category,
                    isExpanded: true,
                    dropdownColor: colors.panel,
                    style: SusTypography.body.copyWith(color: colors.bone),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // SwipeToConfirm
              SwipeToConfirm(
                label: _mode == 'Online' ? 'Create room' : 'Start local game',
                onConfirm: _mode == 'Online' ? _handleCreateOnline : _handleStartLocal,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOnlineFields(SusColors colors) {
    return [
      Text(
        'Room name',
        style: SusTypography.caption.copyWith(color: colors.mute),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _roomNameController,
        maxLength: 25,
        style: SusTypography.body.copyWith(color: colors.bone),
        decoration: const InputDecoration(
          counterText: '',
          hintText: 'Enter room name...',
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '4-digit PIN',
        style: SusTypography.caption.copyWith(color: colors.mute),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _pinController,
        maxLength: 4,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: SusTypography.title.copyWith(
          color: colors.bone,
          letterSpacing: 8,
        ),
        textAlign: TextAlign.center,
        onTap: () {
          if (_pinController.text.isNotEmpty) {
            _pinController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _pinController.text.length,
            );
          }
        },
        decoration: InputDecoration(
          counterText: '',
          hintText: '0000',
          hintStyle: TextStyle(
            color: colors.mute.withValues(alpha: 0.4),
            letterSpacing: 8,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Generate new PIN',
            onPressed: () {
              final newPin = (1000 + math.Random().nextInt(9000)).toString();
              setState(() => _pinController.text = newPin);
            },
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Friends enter this PIN to join your room.',
        style: SusTypography.caption.copyWith(color: colors.mute),
      ),
      const SizedBox(height: 16),
      Text(
        'Max players: $_maxPlayers (min 3, max 12)',
        style: SusTypography.caption.copyWith(color: colors.mute),
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: colors.crimson,
          inactiveTrackColor: colors.line,
          thumbColor: colors.crimsonBright,
          overlayColor: colors.crimson.withAlpha(40),
        ),
        child: Slider(
          value: _maxPlayers.toDouble(),
          min: 3,
          max: 12,
          divisions: 9,
          onChanged: (val) => setState(() => _maxPlayers = val.toInt()),
        ),
      ),
    ];
  }

  List<Widget> _buildLocalFields(SusColors colors) {
    return [
      Text(
        'One phone, everyone together. Add each player’s name.',
        style: SusTypography.body.copyWith(color: colors.mute),
      ),
      const SizedBox(height: 12),
      ...List.generate(_localNameControllers.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _localNameControllers[index],
                  maxLength: 16,
                  style: SusTypography.body.copyWith(color: colors.bone),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Player ${index + 1}',
                  ),
                ),
              ),
              if (_localNameControllers.length > 3) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeLocalPlayer(index),
                  icon: Icon(Icons.close, color: colors.mute),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.panel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: colors.line, width: 1.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _localNameControllers.length >= 12 ? null : _addLocalPlayer,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: colors.line, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Add player',
          style: SusTypography.body.copyWith(
            color: colors.bone,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ];
  }
}
