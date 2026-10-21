import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/profile.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/constants.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Family Profiles')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProfileDialog(),
        child: const Icon(Icons.add),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('No profiles yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isActive = activeProfile?.id == profile.id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: !kIsWeb && profile.photoPath != null
                        ? FileImage(File(profile.photoPath!))
                        : null,
                    child: profile.photoPath == null
                        ? Text(profile.name[0].toUpperCase())
                        : kIsWeb
                            ? ClipOval(
                                child: Image.network(
                                  profile.photoPath!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                  ),
                  title: Text(profile.name),
                  subtitle: Text(
                    '${profile.relationship}${profile.age != null ? ' · ${profile.age} yrs' : ''}',
                  ),
                  trailing: isActive
                      ? const Chip(label: Text('Active'))
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () =>
                              ref.read(activeProfileProvider.notifier).setProfile(profile),
                        ),
                  onTap: () => _showProfileDialog(profile: profile),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showProfileDialog({Profile? profile}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: profile?.name ?? '');
    final ageController = TextEditingController(text: profile?.age?.toString() ?? '');
    String? gender = profile?.gender;
    String? relationship = profile?.relationship;
    String? photoPath = profile?.photoPath;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(profile == null ? 'Add Profile' : 'Edit Profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null && ctx.mounted) {
                          setDialogState(() => photoPath = image.path);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed to pick image: $e')),
                          );
                        }
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: !kIsWeb && photoPath != null
                          ? FileImage(File(photoPath!))
                          : null,
                      child: photoPath == null
                          ? const Icon(Icons.camera_alt)
                          : kIsWeb
                              ? ClipOval(
                                  child: Image.network(
                                    photoPath!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final age = int.tryParse(v.trim());
                        if (age == null || age < 0 || age > 120) {
                          return 'Enter a valid age (0-120)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: AppConstants.genders
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => gender = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: relationship,
                    decoration: const InputDecoration(labelText: 'Relationship'),
                    items: AppConstants.relationships
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => relationship = v),
                    validator: (v) => v == null ? 'Relationship is required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (profile != null)
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(profileRepositoryProvider).delete(profile.id);
                    if (!mounted) return;
                    ref.invalidate(profilesProvider);
                    final activeProfile = ref.read(activeProfileProvider).valueOrNull;
                    if (activeProfile?.id == profile.id) {
                      await ref.read(activeProfileProvider.notifier).refresh();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed to delete profile: $e')),
                      );
                    }
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  final repo = ref.read(profileRepositoryProvider);
                  final newProfile = Profile(
                    id: profile?.id ?? const Uuid().v4(),
                    name: nameController.text.trim(),
                    age: int.tryParse(ageController.text.trim()),
                    gender: gender,
                    relationship: relationship ?? 'Self',
                    photoPath: photoPath,
                    isDefault: profile?.isDefault ?? false,
                  );

                  if (profile == null) {
                    await repo.insert(newProfile);
                  } else {
                    await repo.update(newProfile);
                  }
                  if (!mounted) return;
                  ref.invalidate(profilesProvider);
                  final activeProfile = ref.read(activeProfileProvider).valueOrNull;
                  if (activeProfile?.id == newProfile.id || activeProfile == null) {
                    await ref.read(activeProfileProvider.notifier).refresh();
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to save profile: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
