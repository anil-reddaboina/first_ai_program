import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:ollama_mobile/providers/settings_provider.dart';

enum VoiceState {
  idle,
  listening,
  speaking,
  processing,
}

class VoiceService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  late final AudioRecorder _audioRecorder;
  
  VoiceState _state = VoiceState.idle;
  String _lastRecognizedWords = '';
  bool _isInitialized = false;
  String? _currentSpeakingText;
  bool _isRecording = false;

  // Voice selection
  List<dynamic> _availableVoices = [];
  String? _selectedVoice;

  List<dynamic> get availableVoices => _availableVoices;
  String? get selectedVoice => _selectedVoice;

  VoiceState get state => _state;
  String get lastRecognizedWords => _lastRecognizedWords;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  String? get currentSpeakingText => _currentSpeakingText;

  VoiceService();

  Future<void> fetchVoices() async {
    _availableVoices = await _flutterTts.getVoices;
    notifyListeners();
  }

  Future<void> setVoice(String voiceIdentifier) async {
    _selectedVoice = voiceIdentifier;
    notifyListeners();
  }

  Future<void> _initialize() async {
    try {
      _audioRecorder = AudioRecorder();
      
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await fetchVoices();

      _flutterTts.setCompletionHandler(() {
        _state = VoiceState.idle;
        _currentSpeakingText = null;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      print('Error initializing voice service: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    
    return micStatus.isGranted && storageStatus.isGranted;
  }

  Future<void> startListening({required String localeId}) async {
    if (!_isInitialized) {
      await _initialize();
      if (!_isInitialized) return;
    }

    if (await requestPermissions()) {
      _state = VoiceState.listening;
      _lastRecognizedWords = '';
      notifyListeners();

      await _speechToText.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords;
          notifyListeners();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        onSoundLevelChange: (level) {
          // Handle sound level changes if needed
        },
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _state = VoiceState.idle;
    notifyListeners();
  }

  Future<void> speak(String text, {required String localeId, String? voiceIdentifier}) async {
    if (text.isEmpty) return;

    _currentSpeakingText = text;
    _state = VoiceState.speaking;
    notifyListeners();

    try {
      await _flutterTts.setLanguage(localeId.replaceAll('_', '-'));
      if (voiceIdentifier != null) {
        await _flutterTts.setVoice({'name': voiceIdentifier, 'locale': localeId.replaceAll('_', '-')});
      } else if (_selectedVoice != null) {
         await _flutterTts.setVoice({'name': _selectedVoice!, 'locale': localeId.replaceAll('_', '-')});
      }
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
      _state = VoiceState.idle;
      _currentSpeakingText = null;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _state = VoiceState.idle;
    _currentSpeakingText = null;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (await requestPermissions()) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/recording.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        
        _isRecording = true;
        notifyListeners();
      } catch (e) {
        print('Error starting recording: $e');
      }
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      notifyListeners();
      return path;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _audioRecorder.dispose();
    super.dispose();
  }
} 