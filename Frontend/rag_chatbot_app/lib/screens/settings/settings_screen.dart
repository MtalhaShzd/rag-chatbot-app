import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user  = FirebaseAuth.instance.currentUser!;
    final theme = context.watch<ThemeProvider>();
    final chat  = context.watch<ChatProvider>(); // watch not read

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Profile card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent,
              child: Text(
                (user.displayName ?? 'U')
                  .substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17)),
                const SizedBox(height: 2),
                Text(user.email ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13)),
              ])),
          ]),
        ),
        const SizedBox(height: 20),

        // Appearance
        _SectionTitle('Appearance'),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          trailing: Switch(
            value: theme.isDark,
            activeThumbColor: AppColors.accent,
            onChanged: (_) => theme.toggle()),
        ),

        // Chat Mode
        _SectionTitle('Chat Mode'),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.document_scanner_outlined,
                color: AppColors.textSecondary, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Document Mode',
                  style: TextStyle(fontSize: 15))),
              Switch(
                value: chat.isDocumentMode,
                activeThumbColor: AppColors.accent,
                onChanged: (v) {
                  context.read<ChatProvider>()
                    .setMode(v ? 'document' : 'general');
                },
              ),
            ]),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chat.isDocumentMode
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
              child: Text(
                chat.isDocumentMode
                  ? '📄 Answers from uploaded documents only'
                  : '🌐 Answers from general knowledge',
                style: TextStyle(
                  fontSize: 12,
                  color: chat.isDocumentMode
                    ? AppColors.accent
                    : Colors.green),
              ),
            ),
          ]),
        ),

        // Language
        _SectionTitle('Language'),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.language,
              color: AppColors.textSecondary),
            const SizedBox(width: 12),
            const Text('Response Language',
              style: TextStyle(fontSize: 15)),
            const Spacer(),
            DropdownButton<String>(
              value: chat.language,
              underline: const SizedBox(),
              dropdownColor: AppColors.darkCard,
              items: const [
                DropdownMenuItem(
                  value: 'english',
                  child: Text('English')),
                DropdownMenuItem(
                  value: 'urdu',
                  child: Text('اردو')),
              ],
              onChanged: (v) {
                if (v != null) {
                  context.read<ChatProvider>().setLanguage(v);
                }
              },
            ),
          ]),
        ),

        // Data
        _SectionTitle('Data'),
        _SettingsTile(
          icon: Icons.delete_outline,
          title: 'Clear Chat History',
          iconColor: AppColors.error,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Clear history?'),
                content: const Text(
                  'All messages will be deleted from '
                  'Firestore and local chat.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                  TextButton(
                    onPressed: () async {
                      context.read<ChatProvider>()
                        .clearMessages();
                      await _deleteFirestoreHistory(
                        user.uid);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'History cleared')));
                      }
                    },
                    child: const Text('Clear',
                      style: TextStyle(
                        color: AppColors.error))),
                ],
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.logout,
          title: 'Sign Out',
          iconColor: AppColors.error,
          onTap: () async {
            await context.read<AppAuthProvider>().signOut();
            if (context.mounted) {
              context.go('/auth/login');
            }
          },
        ),
      ]),
    );
  }

  Future<void> _deleteFirestoreHistory(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snap = await firestore
        .collection('users')
        .doc(uid)
        .collection('messages')
        .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Delete history error: $e');
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
    child: Text(title, style: const TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      tileColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 2),
      leading: Icon(icon,
        color: iconColor ?? AppColors.textSecondary),
      title: Text(title,
        style: const TextStyle(fontSize: 15)),
      trailing: trailing ?? (onTap != null
        ? const Icon(Icons.chevron_right,
            color: AppColors.textSecondary)
        : null),
    ),
  );
}