import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  late String _userId;
  bool _isEditing = false;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  bool _isSaving = false;
  bool _isDeleting = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData(_userId);
      if (userData != null && mounted) {
        setState(() {
          _fullNameController.text = userData['fullName'] ?? '';
          _emailController.text = userData['email'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profileNameEmpty'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authService.updateUserData(
        uid: _userId,
        data: {'fullName': _fullNameController.text},
      );

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profileUpdateSuccess'.tr()),
            backgroundColor: const Color(0xFF06A77D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F3460), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header with back button
                Row(
                  children: [
                    Text(
                      'profileAccountInfo'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Profile Avatar with gradient ring
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gradient ring
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF00B4D8),
                              const Color(0xFF00B4D8).withValues(alpha: 0.5),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00B4D8,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Inner circle with icon or selected image
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A2E),
                          image:
                              _selectedImage != null
                                  ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _selectedImage == null
                                ? const Icon(
                                  Icons.person_rounded,
                                  size: 70,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                      // Edit badge - camera icon when editing
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B4D8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1A1A2E),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // User name display
                Text(
                  _fullNameController.text.isNotEmpty
                      ? _fullNameController.text
                      : 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emailController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Info Cards
                _buildInfoCard(
                  icon: Icons.person_outline,
                  label: 'profileFullName'.tr(),
                  child:
                      _isEditing
                          ? TextField(
                            controller: _fullNameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'profileFullName'.tr(),
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          )
                          : Text(
                            _fullNameController.text.isNotEmpty
                                ? _fullNameController.text
                                : '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.email_outlined,
                  label: 'profileEmail'.tr(),
                  isLocked: true,
                  child: Text(
                    _emailController.text.isNotEmpty
                        ? _emailController.text
                        : '-',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'memberSince'.tr(),
                  child: Text(
                    FirebaseAuth.instance.currentUser?.metadata.creationTime !=
                            null
                        ? DateFormat('dd MMM yyyy').format(
                          FirebaseAuth
                              .instance
                              .currentUser!
                              .metadata
                              .creationTime!,
                        )
                        : '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        'profileEdit'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              _isSaving
                                  ? null
                                  : () async {
                                        // Mevcut TextField değerlerini anında sıfırla ki titreme (glitch) olmasın
                                        final userData =
                                            await _authService.getUserData(
                                              _userId,
                                            );
                                        if (mounted) {
                                          setState(() {
                                            _isEditing = false;
                                            _selectedImage = null;
                                            if (userData != null) {
                                              _fullNameController.text =
                                                  userData['fullName'] ?? '';
                                              _emailController.text =
                                                  userData['email'] ?? '';
                                            }
                                          });
                                        }
                                      },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: Text(
                            'profileCancel'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveChanges,
                          icon:
                              _isSaving
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  ),
                          label: Text(
                            _isSaving
                                ? 'profileSaving'.tr()
                                : 'profileSave'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06A77D),
                            disabledBackgroundColor: const Color(
                              0xFF06A77D,
                            ).withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Info hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'profileAccountInfoDesc'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Delete Account Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isDeleting ? null : _showDeleteAccountDialog,
                    icon:
                        _isDeleting
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.delete_forever_outlined,
                              color: Colors.red,
                            ),
                    label: Text(
                      _isDeleting ? 'deleting'.tr() : 'deleteAccount'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Privacy Policy Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _openPrivacyPolicy,
                    icon: Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    label: Text(
                      'privacyPolicy'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'deleteAccount'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'deleteAccountConfirm'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'cancel'.tr(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'delete'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      await _authService.deleteAccount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('deleteAccountSuccess'.tr()),
            backgroundColor: const Color(0xFF06A77D),
          ),
        );

        // Navigate to login page and clear stack
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    // Privacy policy hosted on GitHub Pages
    final locale = context.locale.languageCode;
    final url =
        locale == 'tr'
            ? 'https://pixelprdx.github.io/focusly-privacy/privacy_policy_tr.html'
            : 'https://pixelprdx.github.io/focusly-privacy/privacy_policy.html';

    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required Widget child,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _isEditing && !isLocked
                  ? const Color(0xFF00B4D8).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00B4D8), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
