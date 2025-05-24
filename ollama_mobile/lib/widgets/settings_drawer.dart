import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ollama_mobile/providers/chat_provider.dart';
import 'package:ollama_mobile/providers/settings_provider.dart';
import 'package:ollama_mobile/services/voice_service.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final voiceService = Provider.of<VoiceService>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Supported languages
    final languages = [
      {'label': 'English (US)', 'value': 'en_US'},
      {'label': 'Telugu (India)', 'value': 'te_IN'},
      {'label': 'Hindi (India)', 'value': 'hi_IN'},
      // Add more languages as needed
    ];

    // Fetch voices when the drawer is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (voiceService.availableVoices.isEmpty) {
        voiceService.fetchVoices();
      }
    });

    return Drawer(
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 32,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'R.AI Studio',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your AI Companion',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.model_training,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Model'),
                      subtitle: Text(
                        settings.selectedModel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => _showModelSelector(context, settings),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.thermostat,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Temperature'),
                      subtitle: Text(
                        '${settings.temperature.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.temperature,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: settings.temperature.toStringAsFixed(1),
                          onChanged: (value) {
                            settings.setTemperature(value);
                          },
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.language,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Language'),
                      subtitle: Text(languages.firstWhere((l) => l['value'] == settings.selectedLanguage)['label'] as String),
                      trailing: DropdownButton<String>(
                        value: settings.selectedLanguage,
                        items: languages
                            .map((lang) => DropdownMenuItem<String>(
                                  value: lang['value'],
                                  child: Text(lang['label']!),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settings.setSelectedLanguage(value);
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.record_voice_over,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Voice'),
                      subtitle: voiceService.availableVoices.isEmpty
                          ? Text('No voices found for this language. Try changing the language or check your device TTS settings.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Text(
                              voiceService.selectedVoice != null
                                  ? (voiceService.availableVoices.firstWhere(
                                      (v) => v['name'] == voiceService.selectedVoice,
                                      orElse: () => {'name': 'Default'},
                                    )['name'] as String)
                                  : 'Default',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                      trailing: voiceService.availableVoices.isEmpty
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButton<String>(
                              value: voiceService.selectedVoice,
                              hint: const Text('Select Voice'),
                              items: voiceService.availableVoices
                                  .map<DropdownMenuItem<String>>((voice) {
                                final name = voice['name'] as String? ?? 'Unknown';
                                final gender = voice['gender'] as String?;
                                return DropdownMenuItem<String>(
                                  value: voice['name'] as String,
                                  child: Text(gender != null ? '$name ($gender)' : name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  voiceService.setVoice(value);
                                }
                              },
                            ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      title: Text(
                        'Clear Chat History',
                        style: TextStyle(
                          color: colorScheme.error,
                        ),
                      ),
                      onTap: () => _showClearChatDialog(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showModelSelector(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Model',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Gemma 3 (1B)'),
                subtitle: const Text('Fast and efficient'),
                trailing: settings.selectedModel == 'gemma3:1b'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  settings.setModel('gemma3:1b');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Llama 3.2'),
                subtitle: const Text('More capable but slower'),
                trailing: settings.selectedModel == 'llama3.2:latest'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  settings.setModel('llama3.2:latest');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to clear all chat history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<SettingsProvider>().clearChatHistory();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
} 