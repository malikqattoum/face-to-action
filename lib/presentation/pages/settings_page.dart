import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return ListView(
            children: [
              // Profile section
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'User', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                          if (user?.businessType != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(user!.businessType!, style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // App info
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About Face-to-Action',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Icons.mic,
                title: 'How it works',
                subtitle: 'Learn about voice logging',
                onTap: () => _showHowItWorks(context),
              ),
              const Divider(),

              // Danger zone
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Sign Out?'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<AuthBloc>().add(AuthLogoutRequested());
            context.go('/login');
          },
          child: Text('Sign Out', style: TextStyle(color: AppTheme.error)),
        ),
      ],
    ));
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Face-to-Action'),
      content: const Text(
        'Voice logging for service professionals.\n\n'
        'Record your job details in 30 seconds. '
        'We\'ll transcribe and structure it automatically.\n\n'
        'Built with Flutter + Laravel.',
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it works', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _HowItWorksStep(number: '1', title: 'Tap the mic', description: 'Hold or tap to start recording your voice note (up to 30 seconds).'),
            _HowItWorksStep(number: '2', title: 'Speak naturally', description: '"Just fixed the leak at Mr. Smith\'s, charged \$150, coming back Tuesday."'),
            _HowItWorksStep(number: '3', title: 'AI processes it', description: 'Whisper transcribes your audio, GPT extracts: customer, action, amount, next steps.'),
            _HowItWorksStep(number: '4', title: 'Review & edit', description: 'Check the structured result, make any corrections, save.'),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  const _HowItWorksStep({required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, backgroundColor: AppTheme.primary, child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
