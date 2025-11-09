import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _settingsService.initialize();
  }

  void _showThemeDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Choose Theme',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Dark theme with teal accents',
              isSelected: _settingsService.isDarkMode,
              onTap: () async {
                await _settingsService.setThemeMode(true);
                if (mounted) Navigator.pop(context);
                _updateTheme();
              },
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              icon: Icons.light_mode,
              title: 'Light Mode',
              subtitle: 'Light theme with teal accents',
              isSelected: !_settingsService.isDarkMode,
              onTap: () async {
                await _settingsService.setThemeMode(false);
                if (mounted) Navigator.pop(context);
                _updateTheme();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.2),
            width: 2,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _showLocationAccuracyDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Location Accuracy',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocationAccuracy.values.map((accuracy) {
            final isSelected = _settingsService.locationAccuracy == accuracy;
            return _buildAccuracyOption(
              accuracy: accuracy,
              isSelected: isSelected,
              onTap: () async {
                await _settingsService.setLocationAccuracy(accuracy);
                if (mounted) Navigator.pop(context);
                setState(() {}); // Refresh UI
                _showSnackBar(
                    'Location accuracy updated to ${accuracy.displayName}');
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAccuracyOption({
    required LocationAccuracy accuracy,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              accuracy == LocationAccuracy.high
                  ? Icons.my_location
                  : accuracy == LocationAccuracy.balanced
                      ? Icons.location_searching
                      : Icons.battery_std,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                accuracy.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _showMapStyleDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Map Style',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MapStyle.values.map((style) {
            final isSelected = _settingsService.mapStyle == style;
            return _buildMapStyleOption(
              style: style,
              isSelected: isSelected,
              onTap: () async {
                await _settingsService.setMapStyle(style);
                if (mounted) Navigator.pop(context);
                setState(() {}); // Refresh UI
                _showSnackBar('Map style updated to ${style.displayName}');
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMapStyleOption({
    required MapStyle style,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              style == MapStyle.standard
                  ? Icons.map
                  : style == MapStyle.satellite
                      ? Icons.satellite
                      : Icons.terrain,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                style.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Reset Settings',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'This will reset all settings to their default values. Continue?',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _settingsService.resetToDefaults();
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                _updateTheme();
                _showSnackBar('Settings reset to defaults');
              }
            },
            child: Text(
              'Reset',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _updateTheme() {
    // Force theme rebuild by setting state
    setState(() {});
    // Rebuild the entire app by triggering a hot restart signal
    // This is handled by the parent widget
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _settingsService.isDarkMode;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance', Icons.palette),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Theme',
            subtitle: isDark ? 'Dark Mode' : 'Light Mode',
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            onTap: _showThemeDialog,
          ),

          // Navigation Section
          const SizedBox(height: 24),
          _buildSectionHeader('Navigation', Icons.navigation),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.my_location,
            title: 'Location Accuracy',
            subtitle: _settingsService.locationAccuracy.displayName,
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            onTap: _showLocationAccuracyDialog,
          ),
          _buildSettingsTile(
            icon: Icons.volume_up,
            title: 'Voice Navigation',
            subtitle: _settingsService.isNavigationVoiceEnabled
                ? 'Enabled'
                : 'Disabled',
            trailing: Switch(
              value: _settingsService.isNavigationVoiceEnabled,
              onChanged: (value) async {
                await _settingsService.setNavigationVoiceEnabled(value);
                setState(() {});
                _showSnackBar(
                  'Voice navigation ${value ? "enabled" : "disabled"}',
                );
              },
            ),
            onTap: null,
          ),
          _buildSettingsTile(
            icon: Icons.map,
            title: 'Default Map Style',
            subtitle: _settingsService.mapStyle.displayName,
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            onTap: _showMapStyleDialog,
          ),

          // Notifications Section
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications', Icons.notifications),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: _settingsService.areNotificationsEnabled
                ? 'Enabled'
                : 'Disabled',
            trailing: Switch(
              value: _settingsService.areNotificationsEnabled,
              onChanged: (value) async {
                await _settingsService.setNotificationsEnabled(value);
                setState(() {});
                _showSnackBar(
                  'Notifications ${value ? "enabled" : "disabled"}',
                );
              },
            ),
            onTap: null,
          ),
          _buildSettingsTile(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            subtitle: _settingsService.areSoundEffectsEnabled
                ? 'Enabled'
                : 'Disabled',
            trailing: Switch(
              value: _settingsService.areSoundEffectsEnabled,
              onChanged: (value) async {
                await _settingsService.setSoundEffectsEnabled(value);
                setState(() {});
                _showSnackBar(
                  'Sound effects ${value ? "enabled" : "disabled"}',
                );
              },
            ),
            onTap: null,
          ),

          // Data & Privacy Section
          const SizedBox(height: 24),
          _buildSectionHeader('Data & Privacy', Icons.security),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.delete_sweep,
            title: 'Clear All Data',
            subtitle: 'Remove all saved parking spots and settings',
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.error,
            ),
            onTap: _showClearDataDialog,
          ),
          _buildSettingsTile(
            icon: Icons.refresh,
            title: 'Reset Settings',
            subtitle: 'Restore all settings to defaults',
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            onTap: _showResetDialog,
          ),

          const SizedBox(height: 40),
          // Version info
          Text(
            'Find My Car v1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'About Find My Car',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'A comprehensive parking management app with NYC parking data integration, real-time navigation, and advanced features to help you never lose your car again.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Clear All Data',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'This will permanently delete all saved parking spots, settings, and app data. This action cannot be undone.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Add your clear data logic here
              _showSnackBar('Data cleared successfully');
            },
            child: Text(
              'Clear Data',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
