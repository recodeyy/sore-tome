import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sero/services/api_client.dart';
import 'package:sero/config/constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final response = await ApiClient.upload(
        '/users/me/photo',
        'photo',
        bytes,
        'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (response.statusCode == 200) {
        // Refresh auth state to get the new photoUrl
        ref.invalidate(authProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Loading user data...')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 50, color: Color(0xFF2E7D32))
                      : null,
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text('Status: ${user.status.toUpperCase()}', style: TextStyle(fontSize: 14, color: user.status == 'approved' ? Colors.green : Colors.orange)),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone Number'),
                  subtitle: Text(user.phone.isNotEmpty ? user.phone : 'Not provided'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Flat Number'),
                  subtitle: Text(user.flatNumber),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield),
                  title: const Text('Role Designation'),
                  subtitle: Text(user.role.toUpperCase()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: const Text('Resident Type'),
                  subtitle: Text(user.residentType.toUpperCase()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(authProvider.notifier).logout(); // Logout globally
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); // Erase stack and push login
              },
              icon: const Icon(Icons.logout),
              label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _confirmAccountDeletion(),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('DELETE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _openLegalUrl('Privacy Policy', AppConstants.privacyPolicyUrl),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text('   •   ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              GestureDetector(
                onTap: () => _openLegalUrl('Terms & Conditions', AppConstants.termsConditionsUrl),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => _openLegalUrl('Data Deletion Request', AppConstants.dataDeletionUrl),
              child: const Text(
                'Data Deletion & Support',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action is immediate and IRREVERSIBLE.\n\nYour personal details (name, phone, email, and photo) will be completely anonymized, and all your sessions will be revoked.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmed) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Row(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 12),
          Text('Processing account erasure...'),
        ],
      )),
    );

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been successfully deleted.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openLegalUrl(String title, String url) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You can view the full legal agreement at:'),
              const SizedBox(height: 12),
              SelectableText(
                url,
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('For security or user data inquiries, contact:'),
              const SizedBox(height: 6),
              const SelectableText(
                AppConstants.supportEmail,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}









