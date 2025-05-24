# Ollama Mobile Chat

A Flutter mobile application that provides a beautiful chat interface for interacting with Ollama AI models.

## Prerequisites

1. **Flutter SDK**
   - Install Flutter by following the [official installation guide](https://flutter.dev/docs/get-started/install)
   - Verify installation:
     ```bash
     flutter doctor
     ```
   - Make sure all issues reported by `flutter doctor` are resolved

2. **Ollama Server**
   - Install Ollama from [ollama.ai](https://ollama.ai)
   - Start the Ollama server:
     ```bash
     ollama serve
     ```
   - Pull a model (e.g., gemma3:1b):
     ```bash
     ollama pull gemma3:1b
     ```

3. **Development Environment**
   - Android Studio or VS Code with Flutter extensions
   - iOS development requires macOS and Xcode (for iOS simulator)
   - Android development requires Android Studio and Android SDK

## Setup

1. **Clone and Install Dependencies**
   ```bash
   cd ollama_mobile
   flutter pub get
   ```

2. **Create Required Directories**
   ```bash
   mkdir -p assets/images
   mkdir -p assets/fonts
   ```

3. **Download Inter Font**
   - Download Inter font from [Google Fonts](https://fonts.google.com/specimen/Inter)
   - Place the font files in `assets/fonts/`:
     - Inter-Regular.ttf
     - Inter-Medium.ttf
     - Inter-SemiBold.ttf
     - Inter-Bold.ttf

## Running the App

1. **Start Ollama Server**
   ```bash
   ollama serve
   ```

2. **Run the App**

   For iOS Simulator (macOS only):
   ```bash
   flutter run -d ios
   ```

   For Android Emulator:
   ```bash
   flutter run -d android
   ```

   For Chrome (web):
   ```bash
   flutter run -d chrome
   ```

   To see available devices:
   ```bash
   flutter devices
   ```

## Testing

1. **Unit Tests**
   ```bash
   flutter test
   ```

2. **Manual Testing Checklist**
   - [ ] App launches successfully
   - [ ] Dark/Light theme toggle works
   - [ ] Can connect to Ollama server
   - [ ] Can send and receive messages
   - [ ] Message history persists after app restart
   - [ ] Model selection works
   - [ ] Server URL can be changed
   - [ ] Font size adjustment works
   - [ ] Markdown rendering works in messages
   - [ ] Error handling shows appropriate messages

## Troubleshooting

1. **Connection Issues**
   - Ensure Ollama server is running (`ollama serve`)
   - Check server URL in settings (default: http://localhost:11434)
   - Verify network connectivity

2. **Build Issues**
   - Run `flutter clean` and `flutter pub get`
   - Check Flutter version: `flutter --version`
   - Update Flutter: `flutter upgrade`

3. **iOS-specific Issues**
   - Open iOS simulator: `open -a Simulator`
   - Clean build: `flutter clean && flutter pub get`
   - Run: `flutter run -d ios`

4. **Android-specific Issues**
   - Open Android emulator from Android Studio
   - Clean build: `flutter clean && flutter pub get`
   - Run: `flutter run -d android`

## Development Notes

- The app uses Provider for state management
- Messages are stored locally using SharedPreferences
- The UI follows Material Design 3 guidelines
- Markdown is supported in messages
- The app supports both light and dark themes
- Server URL and model selection can be changed in settings 