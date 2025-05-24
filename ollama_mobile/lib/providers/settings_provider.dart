import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  double _fontSize = 16.0;
  String _selectedModel = 'gemma3:1b';
  double _temperature = 0.7;
  String _selectedLanguage = 'en_US'; // Default to English (US)

  bool get isDarkMode => _isDarkMode;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  double get fontSize => _fontSize;
  String get selectedModel => _selectedModel;
  double get temperature => _temperature;
  String get selectedLanguage => _selectedLanguage;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isNotificationsEnabled = prefs.getBool('isNotificationsEnabled') ?? true;
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _selectedModel = prefs.getString('selectedModel') ?? 'gemma3:1b';
    _temperature = prefs.getDouble('temperature') ?? 0.7;
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'en_US';
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isNotificationsEnabled', _isNotificationsEnabled);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('selectedModel', _selectedModel);
    await prefs.setDouble('temperature', _temperature);
    await prefs.setString('selectedLanguage', _selectedLanguage);
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateFontSize(double size) async {
    _fontSize = size;
    await _saveSettings();
    notifyListeners();
  }

  void setModel(String model) {
    _selectedModel = model;
    _saveSettings();
    notifyListeners();
  }

  void setTemperature(double value) {
    _temperature = value;
    _saveSettings();
    notifyListeners();
  }

  void clearChatHistory() {
    // This will be handled by the ChatProvider
    notifyListeners();
  }

  Future<void> setSelectedLanguage(String language) async {
    _selectedLanguage = language;
    await _saveSettings();
    notifyListeners();
  }
} 