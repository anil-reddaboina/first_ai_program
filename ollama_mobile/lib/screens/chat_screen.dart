import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ollama_mobile/providers/chat_provider.dart';
import 'package:ollama_mobile/providers/settings_provider.dart';
import 'package:ollama_mobile/services/voice_service.dart';
import 'package:ollama_mobile/widgets/message_bubble.dart';
import 'package:ollama_mobile/widgets/settings_drawer.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late VoiceService _voiceService;
  bool _isVoiceMode = false;
  bool _lastInputWasVoice = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _lastMessageCount = chatProvider.messages.length;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatProvider = Provider.of<ChatProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final voiceService = Provider.of<VoiceService>(context, listen: false);

    if (_lastInputWasVoice && chatProvider.messages.length > _lastMessageCount) {
      final lastMsg = chatProvider.messages.last;
      if (lastMsg.role == 'assistant') {
        voiceService.speak(
          lastMsg.content,
          localeId: settingsProvider.selectedLanguage,
          voiceIdentifier: voiceService.selectedVoice,
        );
        _lastInputWasVoice = false;
      }
      _lastMessageCount = chatProvider.messages.length;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleVoiceInput() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (voiceService.state == VoiceState.listening) {
      await voiceService.stopListening();
      if (voiceService.lastRecognizedWords.isNotEmpty) {
        chatProvider.sendMessage(voiceService.lastRecognizedWords);
        _messageController.clear();
        _scrollToBottom();
        _lastInputWasVoice = true; // Mark as voice input
      }
    } else {
      // Pass the selected language to startListening
      await voiceService.startListening(localeId: settingsProvider.selectedLanguage);
    }
  }

  Future<void> _handleVoiceOutput(String text) async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (voiceService.state == VoiceState.speaking) {
      await voiceService.stopSpeaking();
    } else {
       // Pass the selected language and voice identifier to speak
      await voiceService.speak(
        text,
        localeId: settingsProvider.selectedLanguage,
        voiceIdentifier: voiceService.selectedVoice,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = Provider.of<VoiceService>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/user_avatar.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('R.AI Studio'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isVoiceMode ? Icons.keyboard : Icons.mic),
            onPressed: () {
              setState(() {
                _isVoiceMode = !_isVoiceMode;
                if (_isVoiceMode) {
                  _handleVoiceInput();
                } else {
                  Provider.of<VoiceService>(context, listen: false).stopListening();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatProvider.error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatProvider.error,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Clear error
                      Provider.of<ChatProvider>(context, listen: false).clearError();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isVoiceMode
                              ? 'Tap the mic button to start speaking'
                              : 'Type a message below to begin',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider.messages[chatProvider.messages.length - 1 - index];
                        return MessageBubble(
                          message: message,
                          onSpeak: () => _handleVoiceOutput(message.content),
                        );
                      },
                    ),
                    if (chatProvider.isLoading)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: theme.colorScheme.primary,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/user_avatar.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI is thinking...',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.stop, color: theme.colorScheme.error),
                                onPressed: () {
                                  Provider.of<ChatProvider>(context, listen: false).cancelResponse();
                                },
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      _isVoiceMode ? Icons.keyboard : Icons.mic,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isVoiceMode = !_isVoiceMode;
                      });
                      if (!_isVoiceMode) {
                        Provider.of<VoiceService>(context, listen: false).stopListening();
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isVoiceMode
                            ? (voiceService.state == VoiceState.listening ? 'Listening...' : 'Tap mic to speak...')
                            : 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      enabled: !_isVoiceMode || voiceService.state != VoiceState.listening,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isVoiceMode
                      ? IconButton(
                          icon: Icon(
                            voiceService.state == VoiceState.listening ? Icons.stop : Icons.mic,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: _handleVoiceInput,
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: chatProvider.isLoading ? null : _sendMessage,
                          color: theme.colorScheme.primary,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    print('Attempting to send message...');
    final message = _messageController.text.trim();
    print('Message content: "$message"');
    if (message.isNotEmpty) {
      print('Message is not empty, sending...');
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
      _lastInputWasVoice = false; // Mark as text input
    } else {
      print('Message is empty, not sending.');
    }
  }

  void _showSettings(BuildContext context) {
    // Implement the logic to show settings
  }
} 