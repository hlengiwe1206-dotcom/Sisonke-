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
  bool isUploadingImage = false;

  String? avatarUrl;
  String? userEmail;

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

      userEmail = user.email;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        nameController.text =
            data['full_name']?.toString() ?? '';

        avatarUrl =
            data['avatar_url']?.toString();
      } else {
        nameController.text =
            user.userMetadata?['full_name']?.toString() ??
                '';
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error loading profile: $error');

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        showMessage(
          'Could not load your profile.',
          isError: true,
        );
      }
    }
  }

  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage(
        'You are not logged in.',
        isError: true,
      );
      return;
    }

    final fullName = nameController.text.trim();

    if (fullName.isEmpty) {
      showMessage(
        'Please enter your name.',
        isError: true,
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await supabase
          .from('profiles')
          .upsert({
        'id': user.id,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'updated_at':
            DateTime.now().toIso8601String(),
      });

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
          },
        ),
      );

      if (!mounted) return;

      showMessage(
        'Profile updated successfully.',
      );
    } catch (error) {
      debugPrint('Error saving profile: $error');

      if (!mounted) return;

      showMessage(
        'Could not save your profile.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> pickProfilePicture() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image == null) {
        return;
      }

      await uploadProfilePicture(image);
    } catch (error) {
      debugPrint('Error picking image: $error');

      if (!mounted) return;

      showMessage(
        'Could not select image.',
        isError: true,
      );
    }
  }

  Future<void> uploadProfilePicture(
    XFile image,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage(
        'You are not logged in.',
        isError: true,
      );
      return;
    }

    try {
      setState(() {
        isUploadingImage = true;
      });

      final file = File(image.path);

      final fileExtension =
          image.path.split('.').last.toLowerCase();

      final fileName =
          '${user.id}/profile.$fileExtension';

      await supabase.storage
          .from('profile-images')
          .upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType:
                  'image/$fileExtension',
            ),
          );

      final publicUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      avatarUrl = publicUrl;

      await supabase
          .from('profiles')
          .upsert({
        'id': user.id,
        'full_name':
            nameController.text.trim(),
        'avatar_url': avatarUrl,
        'updated_at':
            DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {});

      showMessage(
        'Profile picture updated.',
      );
    } catch (error) {
      debugPrint(
        'Error uploading profile image: $error',
      );

      if (!mounted) return;

      showMessage(
        'Could not upload profile picture.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      debugPrint('Logout error: $error');

      if (!mounted) return;

      showMessage(
        'Could not log out.',
        isError: true,
      );
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : Colors.green,
        ),
      );
  }

  String getInitials() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      return 'S';
    }

    final parts = name.split(' ');

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
        '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
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
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [

                    const SizedBox(height: 20),

                    Center(
                      child: Stack(
                        children: [

                          CircleAvatar(
                            radius: 65,
                            backgroundColor:
                                Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                            backgroundImage:
                                avatarUrl != null &&
                                        avatarUrl!
                                            .isNotEmpty
                                    ? NetworkImage(
                                        avatarUrl!,
                                      )
                                    : null,
                            child:
                                avatarUrl == null ||
                                        avatarUrl!
                                            .isEmpty
                                    ? Text(
                                        getInitials(),
                                        style:
                                            const TextStyle(
                                          fontSize: 38,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      )
                                    : null,
                          ),

                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap:
                                  isUploadingImage
                                      ? null
                                      : pickProfilePicture,
                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .primary,
                                  shape:
                                      BoxShape.circle,
                                  border:
                                      Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child:
                                    isUploadingImage
                                        ? const Padding(
                                            padding:
                                                EdgeInsets.all(
                                              12,
                                            ),
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color:
                                                Colors.white,
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'Profile Picture',
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleMedium,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Center(
                      child: Text(
                        'This picture will be visible to other Sisonke users.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodySmall,
                      ),
                    ),

                    const SizedBox(height: 40),

                    TextField(
                      controller: nameController,
                      textCapitalization:
                          TextCapitalization.words,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Your Full Name',
                        hintText:
                            'Enter your full name',
                        prefixIcon:
                            Icon(Icons.person),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller:
                          TextEditingController(
                        text: userEmail ?? '',
                      ),
                      enabled: false,
                      decoration:
                          const InputDecoration(
                        labelText: 'Email',
                        prefixIcon:
                            Icon(Icons.email),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            isSaving
                                ? null
                                : saveProfile,
                        child:
                            isSaving
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
                                    style:
                                        TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: logout,
                        icon:
                            const Icon(Icons.logout),
                        label:
                            const Text(
                          'Log Out',
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
} 
