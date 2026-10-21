import 'package:flutter/material.dart';

import '../../core/utils/constants.dart';
import '../../widgets/empty_state.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monitor_heart,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text('Version 1.0.0', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const DisclaimerBanner(),
          const SizedBox(height: 16),
          Text(
            AppConstants.measurementDisclaimer,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
            subtitle: Text(
              'Your health data is stored locally on your device. '
              'We do not collect or share your personal health information.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Terms of Service'),
            subtitle: Text(
              'By using VitalTrack, you agree that this app is for informational '
              'purposes only and does not replace professional medical advice.',
            ),
          ),
        ],
      ),
    );
  }
}
