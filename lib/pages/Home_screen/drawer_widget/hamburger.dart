import 'package:flutter/material.dart';
import 'package:the_factory/services/auth_service.dart';

class FactoryDrawer extends StatelessWidget {
  final void Function(String)? onOptionTap;
  const FactoryDrawer({Key? key, this.onOptionTap}) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    print("🔴 Logout button tapped"); // DEBUG

    // Show confirmation dialog WITHOUT closing drawer first
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print("❌ Logout cancelled"); // DEBUG
                  Navigator.pop(dialogContext, false);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  print("✅ Logout confirmed"); // DEBUG
                  Navigator.pop(dialogContext, true);
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00).withOpacity(0.1),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFB8FF00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    print("🔵 Dialog result: $confirm"); // DEBUG

    // Close drawer AFTER dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    // If confirmed, logout
    if (confirm == true && context.mounted) {
      print("🟢 Calling logout..."); // DEBUG
      final authService = AuthService();
      await authService.logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF232723),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF232723)),
              child: Center(
                child: Text(
                  'The Factory',
                  style: TextStyle(
                    color: Color(0xFFB8FF00),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            _DrawerOption(
              icon: Icons.person_outline,
              label: 'Manage Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _DrawerOption(
              icon: Icons.event_note_outlined,
              label: 'Events',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/events');
              },
            ),
            _DrawerOption(
              icon: Icons.play_circle_outline,
              label: 'Online Training',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/training');
              },
            ),
            _DrawerOption(
              icon: Icons.shopping_bag_outlined,
              label: 'Apparel Sales',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/store');
              },
            ),
            const Divider(
              color: Color(0xFF3A3A3A),
              height: 32,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            _DrawerOption(
              icon: Icons.logout_outlined,
              label: 'Logout',
              onTap: () => _handleLogout(context),
              isDestructive: true,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '© 2024 The Factory',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDestructive ? Colors.red.shade400 : const Color(0xFFB8FF00);
    final textColor = isDestructive ? Colors.red.shade400 : Colors.white;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
