import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Colors.grey.shade700,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(context, authState.user?.name ?? 'User'),
            
            const SizedBox(height: 24),
            
            // Finance Features
            _buildFinanceSection(context),
            
            const SizedBox(height: 24),
            
            // Tools & Settings
            _buildToolsSection(context),
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
                    'Manage your profile and preferences',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finance Features',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _buildMenuItem(
                Icons.flag,
                'Goals',
                'Track your financial goals',
                () => Navigator.of(context).pushNamed('/goals'),
                Colors.orange,
              ),
              _buildMenuItem(
                Icons.account_balance,
                'Loans',
                'Manage your loans and payments',
                () => Navigator.of(context).pushNamed('/loans'),
                Colors.red,
              ),
              _buildMenuItem(
                Icons.trending_up,
                'Investments',
                'Track your investment portfolio',
                () => Navigator.of(context).pushNamed('/investments'),
                Colors.green,
              ),
              _buildMenuItem(
                Icons.assessment,
                'Reports',
                'View detailed financial reports',
                () => Navigator.of(context).pushNamed('/reports'),
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tools & Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _buildMenuItem(
                Icons.settings,
                'Settings',
                'App preferences and configurations',
                () => Navigator.of(context).pushNamed('/settings'),
                Colors.grey,
              ),
              _buildMenuItem(
                Icons.help,
                'Help & Support',
                'Get help and contact support',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & support coming soon!')),
                  );
                },
                Colors.blue,
              ),
              _buildMenuItem(
                Icons.info,
                'About',
                'App version and information',
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
                        'A comprehensive personal finance management application with Arabic RTL support.',
                      ),
                    ],
                  );
                },
                Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}