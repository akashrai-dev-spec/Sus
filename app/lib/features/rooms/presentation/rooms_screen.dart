import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/content_column.dart';
import '../../../core/widgets/pin_field.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../online_game/presentation/online_game_controller.dart';
import '../../profile/presentation/profile_controller.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => _isLoading = true);
    final socket = ref.read(socketServiceProvider);
    final res = await socket.listRooms();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['ok'] == true && res['data'] is List) {
          _rooms = (res['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      });
    }
  }

  Future<void> _showPinDialog(Map<String, dynamic> room) async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        String enteredPin = '';
        final pinKey = GlobalKey<PinFieldState>();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = context.colors;

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['name'] as String,
                    style: SusTypography.title.copyWith(color: colors.bone),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter the 4-digit PIN to join.',
                    style: SusTypography.body.copyWith(color: colors.mute),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: PinField(
                      key: pinKey,
                      onChanged: (val) {
                        setSheetState(() => enteredPin = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SwipeToConfirm(
                    label: 'Join room',
                    enabled: enteredPin.length == 4,
                    onConfirm: () async {
                      final controller = ref.read(onlineGameControllerProvider.notifier);
                      final res = await controller.joinRoom(
                        roomId: room['id'] as String,
                        pin: enteredPin,
                      );

                      if (res['ok'] == true) {
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop(true);
                        }
                      } else {
                        if (sheetContext.mounted) {
                          pinKey.currentState?.shake();
                          AppToast.show(
                            context,
                            (res['message'] as String?) ?? 'Wrong PIN. Try again.',
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if ((joined ?? false) && mounted) {
      context.push('/lobby/${room['id']}');
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open rooms',
              style: SusTypography.title.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 6),
            Text(
              'Every room is locked with a PIN. Choose a room to enter.',
              style: SusTypography.body.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.crimson),
                    )
                  : _rooms.isEmpty
                      ? _buildEmptyState(colors)
                      : RefreshIndicator(
                          onRefresh: _fetchRooms,
                          color: colors.crimson,
                          backgroundColor: colors.panel,
                          child: ListView.separated(
                            itemCount: _rooms.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final r = _rooms[index];
                              final count = r['count'] as int;
                              final max = r['max'] as int;
                              final isFull = count >= max;

                              return InkWell(
                                onTap: isFull ? null : () => _showPinDialog(r),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: colors.panel,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: colors.line, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 20,
                                        color: isFull ? colors.mute : const Color(0xFFFFB703),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r['name'] as String,
                                              style: SusTypography.body.copyWith(
                                                color: isFull ? colors.mute : colors.bone,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'Locked with 4-digit PIN',
                                              style: SusTypography.caption.copyWith(color: colors.mute),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          isFull ? '$count/$max full' : '$count/$max',
                                          style: SusTypography.caption.copyWith(
                                            color: isFull ? colors.mute : colors.bone,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SusColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.meeting_room_outlined, size: 56, color: colors.mute),
          const SizedBox(height: 14),
          Text(
            'No rooms available',
            style: SusTypography.heading.copyWith(color: colors.bone),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to create a game and invite friends.',
            style: SusTypography.caption.copyWith(color: colors.mute),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.crimson,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Create a game',
              style: SusTypography.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
