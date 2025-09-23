import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.grey.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(context, authState.user?.name ?? 'User'),
            
            const SizedBox(height: 24),
            
            // App Settings
            _buildAppSettings(context),
            
            const SizedBox(height: 24),
            
            // Financial Settings
            _buildFinancialSettings(context),
            
            const SizedBox(height: 24),
            
            // Security Settings
            _buildSecuritySettings(context),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildAboutSection(context),
            
            const SizedBox(height: 32),
            
            // Sign Out Button
            _buildSignOutButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String userName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your profile',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return _buildSettingsSection(
      'App Settings',
      [
        _buildSettingsTile(
          Icons.language,
          'Language',
          'Arabic',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Language settings coming soon!')),
            );
          },
        ),
        _buildSettingsTile(
          Icons.palette,
          'Theme',
          'System',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme settings coming soon!')),
            );
          },
        ),
        _buildSettingsTile(
          Icons.notifications,
          'Notifications',
          'Enabled',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinancialSettings(BuildContext context) {
    return _buildSettingsSection(
      'Financial Settings',
      [
        _buildSettingsTile(
          Icons.attach_money,
          'Default Currency',
          'SAR',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Currency settings coming soon!')),
            );
          },
        ),
        _buildSettingsTile(
          Icons.category,
          'Categories',
          'Manage',
          () {
            Navigator.of(context).pushNamed('/categories');
          },
        ),
        _buildSettingsTile(
          Icons.backup,
          'Data Backup',
          'Auto',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup settings coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySettings(BuildContext context) {
    return _buildSettingsSection(
      'Security',
      [
        _buildSettingsTile(
          Icons.fingerprint,
          'Biometric Login',
          'Disabled',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric login coming soon!')),
            );
          },
        ),
        _buildSettingsTile(
          Icons.lock,
          'Change Password',
          '',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password change coming soon!')),
            );
          },
        ),
        _buildSettingsTile(
          Icons.security,
          'Privacy Policy',
          '',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy policy coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSettingsSection(
      'About',
      [
        _buildSettingsTile(
          Icons.info,
          'App Version',
          '1.0.0',
          () {
            showAboutDialog(
              context: context,
              applicationName: 'Finance App',
              applicationVersion: '1.0.0',
              applicationIcon: Icon(
                Icons.account_balance_wallet,
                color: Colors.blue.shade600,
                size: 32,
              ),
              children: [
                const Text(
                  'A comprehensive personal finance management application with Arabic RTL support and AI integration.',
                ),
              ],
            );
          },
        ),
        _buildSettingsTile(
          Icons.help,
          'Help & Support',
          '',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & support coming soon!')),
            );
          },
        ),
        _buildSettingsTile(
          Icons.star_rate,
          'Rate App',
          '',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rate app feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}