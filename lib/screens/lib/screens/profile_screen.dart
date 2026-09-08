import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  final ImagePicker imagePicker =
      ImagePicker();

  final TextEditingController nameController =
      TextEditingController();

  String? avatarUrl;

  bool isLoading = true;
  bool isSaving = false;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        nameController.text =
            data['full_name']?.toString() ?? '';

        avatarUrl =
            data['avatar_url']?.toString();
      } else {
        nameController.text =
            user.email?.split('@').first ?? '';
      }

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Error loading profile: $error',
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final XFile? image =
          await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image == null) return;

      setState(() {
        isUploading = true;
      });

      final Uint8List imageBytes =
          await image.readAsBytes();

      final String fileExtension =
          image.name.contains('.')
              ? image.name.split('.').last
              : 'jpg';

      final String filePath =
          '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await supabase.storage
          .from('profile-photos')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType:
                  'image/$fileExtension',
              upsert: true,
            ),
          );

      final String publicUrl = supabase
          .storage
          .from('profile-photos')
          .getPublicUrl(filePath);

      await supabase
          .from('profiles')
          .upsert({
            'id': user.id,
            'full_name':
                nameController.text.trim(),
            'avatar_url': publicUrl,
            'updated_at':
                DateTime.now().toIso8601String(),
          });

      if (!mounted) return;

      setState(() {
        avatarUrl = publicUrl;
        isUploading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile picture updated successfully',
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Error uploading profile image: $error',
      );

      if (mounted) {
        setState(() {
          isUploading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> saveProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final name =
          nameController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter your name',
            ),
          ),
        );

        return;
      }

      setState(() {
        isSaving = true;
      });

      await supabase
          .from('profiles')
          .upsert({
            'id': user.id,
            'full_name': name,
            'avatar_url': avatarUrl,
            'updated_at':
                DateTime.now().toIso8601String(),
          });

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      debugPrint(
        'Error saving profile: $error',
      );

      if (mounted) {
        setState(() {
          isSaving = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $error',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: isUploading
                        ? null
                        : pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundImage:
                              avatarUrl != null &&
                                      avatarUrl!
                                          .isNotEmpty
                                  ? NetworkImage(
                                      avatarUrl!,
                                    )
                                  : null,
                          child: avatarUrl == null ||
                                  avatarUrl!
                                      .isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                )
                              : null,
                        ),

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 22,
                            child: isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextButton.icon(
                    onPressed: isUploading
                        ? null
                        : pickAndUploadImage,
                    icon: const Icon(
                      Icons.photo_library,
                    ),
                    label: const Text(
                      'Upload Profile Picture',
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: nameController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Display Name',
                      hintText:
                          'Enter your full name',
                      prefixIcon:
                          Icon(Icons.person_outline),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    readOnly: true,
                    controller:
                        TextEditingController(
                      text: user?.email ?? '',
                    ),
                    decoration:
                        const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          Icon(Icons.email_outlined),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : saveProfile,
                      child: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Your display name and profile picture can be used to identify you to other Sisonke users.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
