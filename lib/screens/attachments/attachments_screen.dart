import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/attachment.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/empty_state.dart';

final attachmentsProvider = FutureProvider.family<List<Attachment>, String>((ref, profileId) {
  return ref.watch(attachmentRepositoryProvider).getByProfile(profileId);
});

class AttachmentsScreen extends ConsumerWidget {
  const AttachmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Attachments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickFile(context, ref, profile?.id),
        child: const Icon(Icons.attach_file),
      ),
      body: profile == null
          ? const EmptyStateWidget(
              icon: Icons.person_off,
              title: 'No profile',
              message: 'Select a profile first.',
            )
          : ref.watch(attachmentsProvider(profile.id)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Error',
                  message: e.toString(),
                ),
                data: (attachments) {
                  if (attachments.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.folder_open,
                      title: 'No attachments',
                      message:
                          'Attach prescriptions, lab reports, or doctor recommendations.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final a = attachments[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(_iconForType(a.fileType)),
                          title: Text(a.fileName),
                          subtitle: Text(AppDateUtils.formatDate(a.timestamp)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref.read(attachmentRepositoryProvider).delete(a.id);
                              ref.invalidate(attachmentsProvider(profile.id));
                            },
                          ),
                          onTap: () => _openAttachment(context, a),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  IconData _iconForType(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image') || type == 'jpg' || type == 'jpeg' || type == 'png') {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  Future<void> _pickFile(
    BuildContext context,
    WidgetRef ref,
    String? profileId,
  ) async {
    if (profileId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final attachment = Attachment(
      id: const Uuid().v4(),
      filePath: file.path!,
      fileName: file.name,
      fileType: file.extension ?? 'unknown',
      timestamp: DateTime.now(),
      profileId: profileId,
    );

    await ref.read(attachmentRepositoryProvider).insert(attachment);
    ref.invalidate(attachmentsProvider(profileId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment saved')),
      );
    }
  }

  Future<void> _openAttachment(BuildContext context, Attachment a) async {
    final isImage = a.fileType.toLowerCase().contains('jpg') ||
        a.fileType.toLowerCase().contains('jpeg') ||
        a.fileType.toLowerCase().contains('png') ||
        a.fileType.toLowerCase().contains('image');

    if (isImage) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(a.fileName),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      await Share.shareXFiles([XFile(a.filePath)], subject: a.fileName);
                    },
                  ),
                ],
              ),
              InteractiveViewer(
                child: Image.file(
                  File(a.filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Image file not found on device')),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      try {
        await Share.shareXFiles(
          [XFile(a.filePath)],
          subject: a.fileName,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: $e')),
          );
        }
      }
    }
  }
}
