import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/name_generator.dart';
import '../data/profile_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main()');
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileRepository(prefs);
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return UserProfileNotifier(repo);
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._repo) : super(_repo.loadProfile());

  final ProfileRepository _repo;

  void updateName(String name) {
    state = state.copyWith(name: name.trim().isEmpty ? state.name : name.trim());
    _repo.saveProfile(state);
  }

  void updateColor(String color) {
    state = state.copyWith(color: color);
    _repo.saveProfile(state);
  }

  void rollRandomName() {
    state = state.copyWith(name: NameGenerator.generateRandomName());
    _repo.saveProfile(state);
  }

  void setResumeToken(String token) {
    state = state.copyWith(resumeToken: token);
    _repo.saveProfile(state);
  }

  void updateServerUrl(String url) {
    state = state.copyWith(serverUrl: url.trim());
    _repo.saveProfile(state);
  }

  void updateLastLocalNames(List<String> names) {
    state = state.copyWith(lastLocalNames: names);
    _repo.saveProfile(state);
  }
}
