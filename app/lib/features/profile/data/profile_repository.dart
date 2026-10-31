import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/name_generator.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.color,
    this.resumeToken,
    this.lastLocalNames = const ['Player 1', 'Player 2', 'Player 3'],
    this.serverUrl = const String.fromEnvironment(
      'SERVER_URL',
      defaultValue: 'https://sus-server-t5te.onrender.com',
    ),
  });

  final String name;
  final String color;
  final String? resumeToken;
  final List<String> lastLocalNames;
  final String serverUrl;

  UserProfile copyWith({
    String? name,
    String? color,
    String? resumeToken,
    List<String>? lastLocalNames,
    String? serverUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      color: color ?? this.color,
      resumeToken: resumeToken ?? this.resumeToken,
      lastLocalNames: lastLocalNames ?? this.lastLocalNames,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        if (resumeToken != null) 'resumeToken': resumeToken,
        'lastLocalNames': lastLocalNames,
        'serverUrl': serverUrl,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['serverUrl'] as String?;
    // Default to the live Render cloud server unless a custom non-localhost URL was saved
    final serverUrl = (rawUrl != null && rawUrl.isNotEmpty && rawUrl != 'http://localhost:3000')
        ? rawUrl
        : const String.fromEnvironment(
            'SERVER_URL',
            defaultValue: 'https://sus-server-t5te.onrender.com',
          );

    return UserProfile(
      name: (json['name'] as String?) ?? NameGenerator.generateRandomName(),
      color: (json['color'] as String?) ?? NameGenerator.getRandomColor(),
      resumeToken: json['resumeToken'] as String?,
      lastLocalNames: (json['lastLocalNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Player 1', 'Player 2', 'Player 3'],
      serverUrl: serverUrl,
    );
  }
}

class ProfileRepository {
  const ProfileRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'sus_user_profile';

  UserProfile loadProfile() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final fresh = UserProfile(
        name: NameGenerator.generateRandomName(),
        color: NameGenerator.getRandomColor(),
      );
      saveProfile(fresh);
      return fresh;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      final fallback = UserProfile(
        name: NameGenerator.generateRandomName(),
        color: NameGenerator.getRandomColor(),
      );
      saveProfile(fallback);
      return fallback;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}
