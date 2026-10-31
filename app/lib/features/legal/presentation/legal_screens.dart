import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.ink,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'Terms of Service',
              style: SusTypography.title.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: October 2026',
              style: SusTypography.caption.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 20),
            _buildSection(
              colors: colors,
              title: '1. Acceptance of Terms',
              content:
                  'By downloading, accessing, or playing Sus (the "Game", available via mobile application and web client), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not install or use the application.',
            ),
            _buildSection(
              colors: colors,
              title: '2. License & Intellectual Property',
              content:
                  'Sus is released as open-source software under the MIT License. You are granted a personal, revocable, non-exclusive license to play, modify, and self-host the game software in accordance with the license terms.',
            ),
            _buildSection(
              colors: colors,
              title: '3. Community Conduct & Content',
              content:
                  'Players are responsible for room names and custom clues entered during gameplay. You agree not to use vulgarity, hate speech, harassment, or abusive language. The game incorporates automated word filtering to preserve safe community standards.',
            ),
            _buildSection(
              colors: colors,
              title: '4. Multiplayer Rooms & Fair Play',
              content:
                  'Online multiplayer rooms are protected by 4-digit PINs. Rate-limiting is strictly enforced against brute-force room attacks. Attempting to reverse-engineer server sockets or manipulate game state to cheat will result in immediate session termination.',
            ),
            _buildSection(
              colors: colors,
              title: '5. Limitation of Liability',
              content:
                  'The Game is provided "AS IS", without warranties of any kind. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability arising from the use or distribution of the software.',
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.ink,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'Privacy Policy',
              style: SusTypography.title.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: October 2026',
              style: SusTypography.caption.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 20),
            _buildSection(
              colors: colors,
              title: '1. Zero Personal Data Collection',
              content:
                  'Sus is engineered with privacy as a foundational principle. We do NOT collect, sell, or monetize your personal information. We do not require registration, email addresses, phone numbers, or social media logins.',
            ),
            _buildSection(
              colors: colors,
              title: '2. Local On-Device Storage',
              content:
                  'Your chosen player handle, avatar color, and local pass-and-play player rosters are stored strictly on your local device via standard sandboxed storage (SharedPreferences / LocalStorage). This data never leaves your device unless you join an online room.',
            ),
            _buildSection(
              colors: colors,
              title: '3. Ephemeral Multiplayer Data',
              content:
                  'When you create or join an online game room, transient session tokens and room state are held in memory on the server for the duration of the match. All room PINs are cryptographically hashed using Argon2. Room records are permanently deleted 2 minutes after all players disconnect.',
            ),
            _buildSection(
              colors: colors,
              title: '4. Third-Party Analytics & Tracking',
              content:
                  'Sus contains ZERO third-party advertising SDKs, tracking pixels, or commercial telemetry beacons. Fonts (Inter) and assets are bundled locally to eliminate unneeded runtime network requests.',
            ),
            _buildSection(
              colors: colors,
              title: '5. Inquiries',
              content:
                  'If you have questions regarding data privacy or self-hosting security standards, please review our open-source codebase on GitHub or contact the maintainers at akashrai.dev.',
            ),
          ],
        ),
      ),
    );
  }
}

class LegalNoticeScreen extends StatelessWidget {
  const LegalNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.ink,
      appBar: AppBar(
        title: const Text('Legal Notice & Disclaimers'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'Legal Notice & Disclaimers',
              style: SusTypography.title.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 6),
            Text(
              'Information in accordance with digital services regulations',
              style: SusTypography.caption.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 20),
            _buildSection(
              colors: colors,
              title: 'Project Authorship & Rights',
              content:
                  'Sus is an independent open-source social deduction game conceived and developed by Akash Rai (akashrai.dev) and Aaryan Banskota. All brand design assets, Oni mask logo vectors, and game state logic are copyrighted © 2026 under the MIT License.',
            ),
            _buildSection(
              colors: colors,
              title: 'Trademark Disclaimers',
              content:
                  'Sus is an original turn-based word and deduction game. Any references to cultural tropes, public categories, or famous personalities in the word bank are used purely for trivia and descriptive party entertainment under fair use principles.',
            ),
            _buildSection(
              colors: colors,
              title: 'Open Source Software Components',
              content:
                  'Built with Flutter, Dart, Node.js, TypeScript, and Socket.IO. We express gratitude to the open-source community for making privacy-first gaming possible.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Sus',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Copyright © 2026 akashrai.dev',
              ),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('View All Open Source Licenses'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: colors.line, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSection({
  required SusColors colors,
  required String title,
  required String content,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.panel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.line, width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SusTypography.body.copyWith(
            color: colors.bone,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: SusTypography.body.copyWith(
            color: colors.mute,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
