import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _fullNameController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  File? _selectedImage;

  String? _avatarUrl;
  String? _errorMessage;

  final String _bucketName = 'profile-pictures';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        if (!mounted) return;

        setState(() {
          _fullNameController.text =
              data['full_name']?.toString() ?? '';

          _avatarUrl =
              data['avatar_url']?.toString();

          _isLoading = false;
        });
      } else {
        // No profile yet.
        // Pre-fill with the user's metadata if available.
        if (!mounted) return;

        setState(() {
          _fullNameController.text =
              user.userMetadata?['full_name']?.toString() ??
                  '';

          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('LOAD PROFILE ERROR: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to load profile.\n\n$error';

        _isLoading = false;
      });
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final XFile? pickedImage =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedImage == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    } catch (error) {
      debugPrint('IMAGE PICKER ERROR: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to select image.\n\n$error';
      });

      _showError(
        'Unable to select image:\n$error',
      );
    }
  }

  // ============================================================
  // UPLOAD PROFILE IMAGE
  // ============================================================

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) {
      return _avatarUrl;
    }

    try {
      setState(() {
        _isUploadingImage = true;
        _errorMessage = null;
      });

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          'You are not logged in. Please sign in again.',
        );
      }

      final String fileExtension =
          _selectedImage!.path
              .split('.')
              .last
              .toLowerCase();

      final String safeExtension =
          fileExtension.isEmpty
              ? 'jpg'
              : fileExtension;

      // IMPORTANT:
      // The first folder is the user's ID.
      // This matches the Supabase Storage policy.
      final String filePath =
          '${user.id}/profile.$safeExtension';

      debugPrint(
        'Uploading image to bucket: $_bucketName',
      );

      debugPrint(
        'Uploading image path: $filePath',
      );

      // Upload file
      await supabase.storage
          .from(_bucketName)
          .upload(
            filePath,
            _selectedImage!,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType:
                  'image/$safeExtension',
            ),
          );

      // Get public URL
      final String publicUrl =
          supabase.storage
              .from(_bucketName)
              .getPublicUrl(filePath);

      debugPrint(
        'PROFILE IMAGE UPLOAD SUCCESS: $publicUrl',
      );

      if (!mounted) return publicUrl;

      setState(() {
        _avatarUrl = publicUrl;
        _isUploadingImage = false;
      });

      return publicUrl;
    } on StorageException catch (error) {
      debugPrint(
        'SUPABASE STORAGE ERROR: ${error.message}',
      );

      if (mounted) {
        setState(() {
          _isUploadingImage = false;

          _errorMessage =
              'Supabase Storage Error:\n'
              '${error.message}\n\n'
              'Status Code: ${error.statusCode}';
        });
      }

      rethrow;
    } catch (error) {
      debugPrint(
        'PROFILE IMAGE UPLOAD ERROR: $error',
      );

      if (mounted) {
        setState(() {
          _isUploadingImage = false;

          _errorMessage =
              'Image upload failed:\n\n$error';
        });
      }

      rethrow;
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final String fullName =
        _fullNameController.text.trim();

    if (fullName.isEmpty) {
      _showError(
        'Please enter your full name.',
      );

      return;
    }

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          'No authenticated user found. '
          'Please sign in again.',
        );
      }

      // Upload image first if the user selected one.
      final String? uploadedAvatarUrl =
          await _uploadProfileImage();

      // Save or update profile.
      await supabase
          .from('profiles')
          .upsert(
            {
              'id': user.id,
              'full_name': fullName,
              'avatar_url': uploadedAvatarUrl,
              'updated_at':
                  DateTime.now()
                      .toIso8601String(),
            },
            onConflict: 'id',
          );

      // Also update Supabase Auth metadata.
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'avatar_url': uploadedAvatarUrl,
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        _avatarUrl = uploadedAvatarUrl;
        _selectedImage = null;
        _isSaving = false;
      });

      _showSuccess(
        'Profile saved successfully.',
      );
    } on StorageException catch (error) {
      debugPrint(
        'SAVE STORAGE ERROR: '
        '${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Profile picture upload failed.\n\n'
        'Supabase says:\n'
        '${error.message}\n\n'
        'Status Code: '
        '${error.statusCode}',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'DATABASE ERROR: ${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Database error while saving profile.\n\n'
        '${error.message}\n\n'
        'Details: ${error.details ?? 'None'}\n'
        'Hint: ${error.hint ?? 'None'}',
      );
    } catch (error) {
      debugPrint(
        'SAVE PROFILE ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Unable to save profile.\n\n'
        'Error:\n$error',
      );
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context)
          .popUntil((route) => route.isFirst);
    } catch (error) {
      debugPrint(
        'SIGN OUT ERROR: $error',
      );

      _showError(
        'Unable to sign out.\n\n$error',
      );
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(
            seconds: 6,
          ),
        ),
      );
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_avatarUrl != null &&
        _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Profile',
          ),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final ImageProvider? profileImage =
        _getProfileImage();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            children: [

              // ==========================================
              // PROFILE PICTURE
              // ==========================================

              const SizedBox(height: 20),

              GestureDetector(
                onTap: _isUploadingImage ||
                        _isSaving
                    ? null
                    : _pickImage,

                child: Stack(
                  clipBehavior: Clip.none,

                  children: [

                    CircleAvatar(
                      radius: 105,

                      backgroundColor:
                          Colors.grey.shade300,

                      backgroundImage:
                          profileImage,

                      child:
                          profileImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 100,
                                  color:
                                      Colors.grey
                                          .shade600,
                                )
                              : null,
                    ),

                    Positioned(
                      right: 0,
                      bottom: 0,

                      child:
                          Container(
                        width: 70,
                        height: 70,

                        decoration:
                            const BoxDecoration(
                          color: Colors.black,
                          shape:
                              BoxShape.circle,
                        ),

                        child:
                            _isUploadingImage
                                ? const Padding(
                                    padding:
                                        EdgeInsets
                                            .all(20),

                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,
                                      strokeWidth:
                                          3,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .camera_alt,
                                    color:
                                        Colors.white,
                                    size: 32,
                                  ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Tap your picture to change it',

                style: TextStyle(
                  fontSize: 16,
                  color:
                      Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 50),

              // ==========================================
              // FULL NAME
              // ==========================================

              TextField(
                controller:
                    _fullNameController,

                textCapitalization:
                    TextCapitalization.words,

                decoration:
                    InputDecoration(
                  labelText:
                      'Full Name',

                  prefixIcon:
                      const Icon(
                    Icons.person_outline,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==========================================
              // EMAIL
              // ==========================================

              TextField(
                enabled: false,

                controller:
                    TextEditingController(
                  text: supabase
                          .auth
                          .currentUser
                          ?.email ??
                      '',
                ),

                decoration:
                    InputDecoration(
                  labelText:
                      'Email Address',

                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // ERROR DISPLAY
              // ==========================================

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red.shade50,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    border: Border.all(
                      color:
                          Colors.red.shade300,
                    ),
                  ),

                  child: Text(
                    _errorMessage!,

                    style: TextStyle(
                      color:
                          Colors.red.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // ==========================================
              // SAVE PROFILE BUTTON
              // ==========================================

              SizedBox(
                width: double.infinity,
                height: 60,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      _isSaving ||
                              _isUploadingImage
                          ? null
                          : _saveProfile,

                  icon: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,

                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.save,
                        ),

                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Save Profile',

                    style:
                        const TextStyle(
                      fontSize: 20,
                    ),
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==========================================
              // SIGN OUT BUTTON
              // ==========================================

              SizedBox(
                width: double.infinity,
                height: 60,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      _isSaving
                          ? null
                          : _signOut,

                  icon: const Icon(
                    Icons.logout,
                  ),

                  label: const Text(
                    'Sign Out',

                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),

                  style:
                      OutlinedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }
}
