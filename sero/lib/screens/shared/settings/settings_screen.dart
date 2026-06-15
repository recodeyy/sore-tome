import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('General'),
          _buildToggleItem('Dark Mode', Icons.dark_mode_outlined, _darkMode, (v) => setState(() => _darkMode = v)),
          _buildToggleItem('Notifications', Icons.notifications_none_outlined, _notifications, (v) => setState(() => _notifications = v)),
          _buildNavigationItem('Language', 'English (US)', Icons.language_outlined, () {}),

          const SizedBox(height: 32),
          _buildSectionHeader('Account'),
          _buildNavigationItem('Change Password', null, Icons.lock_outline, () {}),
          _buildNavigationItem('Privacy', null, Icons.privacy_tip, () {}),

          const SizedBox(height: 32),
          _buildSectionHeader('About'),
          _buildNavigationItem('App Version', '1.0.0 (BETA)', Icons.info_outline, () {}),
          _buildNavigationItem('Terms & Conditions', null, Icons.description_outlined, () {}),
          _buildNavigationItem('Privacy Policy', null, Icons.policy_outlined, () {}),

          const SizedBox(height: 32),
          _buildSectionHeader('Support'),
          _buildNavigationItem('Help Center', null, Icons.help_outline, () {}),
          _buildNavigationItem('Contact Support', null, Icons.support_agent_outlined, () {}),
          
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Sero Admin Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Powered by Advanced Agentic Coding',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleItem(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF64748B), size: 22),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: kPrimaryGreen,
        ),
      ),
    );
  }

  Widget _buildNavigationItem(String title, String? trailingText, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF64748B), size: 22),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(
                trailingText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}
