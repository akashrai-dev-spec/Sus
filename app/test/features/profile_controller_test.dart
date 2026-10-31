import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sus/features/profile/data/profile_repository.dart';
import 'package:sus/features/profile/presentation/profile_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UserProfileNotifier updates profile name and color and saves to repo', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileRepository(prefs);
    final notifier = UserProfileNotifier(repo);

    expect(notifier.state.name.isNotEmpty, isTrue);

    notifier.updateName('Custom Alias');
    expect(notifier.state.name, 'Custom Alias');

    notifier.updateColor('#1D4ED8');
    expect(notifier.state.color, '#1D4ED8');

    // Reload from fresh repo instance
    final reloaded = repo.loadProfile();
    expect(reloaded.name, 'Custom Alias');
    expect(reloaded.color, '#1D4ED8');
  });
}
