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

  final TextEditingController nameController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  bool isLoading = true;
  bool isSaving = false;

  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        if (mounted) {
          setState(() {
            nameController.text =
                profile['full_name']?.toString() ?? '';

            avatarUrl =
                profile['avatar_url']?.toString();

            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            nameController.text =
                user.userMetadata?['full_name']?.toString() ??
                    '';

            isLoading = false;
          });
        }
      }
    } catch (error) {
      debugPrint('Error loading profile: $error');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedImage =
          await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1000,
      );

      if (pickedImage == null) return;

      await uploadProfileImage(pickedImage);
    } catch (error) {
      debugPrint('Error picking image: $error');

      if (mounted) {
        showMessage(
          'Unable to select image',
          isError: true,
        );
      }
    }
  }

  Future<void> uploadProfileImage(
    XFile pickedImage,
  ) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      if (mounted) {
        setState(() {
          isSaving = true;
        });
      }

      final file = File(pickedImage.path);

      final fileExtension =
          pickedImage.name.split('.').last;

      final filePath =
          '${user.id}/avatar.$fileExtension';

      await supabase.storage
          .from('avatars')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      final publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      if (mounted) {
        setState(() {
          avatarUrl =
              '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        });
      }

      await saveProfile(showSuccessMessage: false);

      if (mounted) {
        showMessage(
          'Profile picture updated successfully',
        );
      }
    } catch (error) {
      debugPrint(
        'Error uploading profile picture: $error',
      );

      if (mounted) {
        showMessage(
          'Unable to upload profile picture',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> saveProfile({
    bool showSuccessMessage = true,
  }) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      if (mounted) {
        setState(() {
          isSaving = true;
        });
      }

      final fullName =
          nameController.text.trim();

      await supabase
          .from('profiles')
          .upsert(
        {
          'id': user.id,
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'updated_at':
              DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'avatar_url': avatarUrl,
          },
        ),
      );

      if (mounted && showSuccessMessage) {
        showMessage(
          'Profile saved successfully',
        );
      }
    } catch (error) {
      debugPrint('Error saving profile: $error');

      if (mounted) {
        showMessage(
          'Unable to save profile',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                  ),
                  title: const Text(
                    'Choose from gallery',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    pickImage(
                      ImageSource.gallery,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                  ),
                  title: const Text(
                    'Take a photo',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    pickImage(
                      ImageSource.camera,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context)
          .pushNamedAndRemoveUntil(
        '/auth',
        (route) => false,
      );
    } catch (error) {
      debugPrint('Error signing out: $error');

      if (mounted) {
        showMessage(
          'Unable to sign out',
          isError: true,
        );
      }
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              GestureDetector(
                onTap: isSaving
                    ? null
                    : showImageOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor:
                          Colors.grey.shade300,
                      backgroundImage:
                          avatarUrl != null &&
                                  avatarUrl!.isNotEmpty
                              ? NetworkImage(
                                  avatarUrl!,
                                )
                              : null,
                      child: avatarUrl == null ||
                              avatarUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey,
                            )
                          : null,
                    ),

                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding:
                            const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Tap your picture to change it',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                enabled: false,
                controller: TextEditingController(
                  text: user?.email ?? '',
                ),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : saveProfile,
                  icon: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save,
                        ),
                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : 'Save Profile',
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed:
                      isSaving ? null : signOut,
                  icon: const Icon(
                    Icons.logout,
                  ),
                  label: const Text(
                    'Sign Out',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
