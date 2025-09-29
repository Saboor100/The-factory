import 'package:flutter/material.dart';

class FactoryDrawer extends StatelessWidget {
  final void Function(String)? onOptionTap;
  const FactoryDrawer({Key? key, this.onOptionTap}) : super(key: key);

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
            _DrawerOption(
              icon: Icons.logout_outlined,
              label: 'Logout',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
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

  const _DrawerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFB8FF00)),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
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
