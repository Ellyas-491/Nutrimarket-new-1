import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastRecognized = '';

  // Guards against stale callbacks / overlapping calls.
  int _listenSession = 0;
  int _speakSession = 0;
  bool _finalHandled = false;
  bool _startListeningInFlight = false;

  VoidCallback? onTtsDone;
  Function(String text)? _onResult;
  Function(bool isListening)? _onStateChange;
  Function(String finalSentence)? _onFinalSentence;
  Function()? _onErrorTimeout;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  void clearListeners() {
    // Invalidate any in-flight session so its late callbacks are ignored.
    _listenSession++;
    _speakSession++;
    _onResult = null;
    _onStateChange = null;
    _onFinalSentence = null;
    _onErrorTimeout = null;
    _lastRecognized = '';
    _finalHandled = false;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        await _tts.awaitSpeakCompletion(true);
        final engines = await _tts.getEngines;
        if (engines.contains('com.google.android.tts')) {
          await _tts.setEngine('com.google.android.tts');
        }
      } else if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
      }

      var langResult = await _tts.setLanguage('id-ID');
      if (langResult != 1) {
        await _tts.setLanguage('id_ID');
      }
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('TTS Started playing audio');
      });

      _tts.setCompletionHandler(() {
        final finishedSession = _speakSession;
        _isSpeaking = false;
        debugPrint('TTS Completed audio');
        final cb = onTtsDone;
        onTtsDone = null;
        if (finishedSession == _speakSession) {
          cb?.call();
        }
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
        final cb = onTtsDone;
        onTtsDone = null;
        cb?.call();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('VoiceService init error: $e');
    }
  }

  void _handleSpeechError(dynamic error) {
    final errorMsg = error?.errorMsg?.toString() ?? error.toString();
    debugPrint('STT Error: $errorMsg');
    _isListening = false;
    _onStateChange?.call(false);

    if (!_finalHandled &&
        (errorMsg == 'error_speech_timeout' ||
            errorMsg == 'error_no_match')) {
      _finalHandled = true;
      _onErrorTimeout?.call();
    }
  }

  void _handleSpeechStatus(String status) {
    debugPrint('STT Status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _onStateChange?.call(false);

      if (_finalHandled) return;

      final sentence = _lastRecognized.trim();
      if (sentence.isNotEmpty) {
        _finalHandled = true;
        _lastRecognized = '';
        _onFinalSentence?.call(sentence);
      } else if (_onErrorTimeout != null) {
        _finalHandled = true;
        _onErrorTimeout?.call();
      }
    }
  }

  Future<bool> startListening({
    required Function(String text) onResult,
    required Function(bool isListening) onStateChange,
    Function(String finalSentence)? onFinalSentence,
    Function()? onErrorTimeout,
    Function(double level)? onSoundLevel,
  }) async {
    // Prevent overlapping start calls.
    if (_startListeningInFlight) {
      debugPrint('startListening ignored: already starting a session');
      return false;
    }
    _startListeningInFlight = true;

    try {
      await init();

      if (_isSpeaking) {
        await stopSpeaking();
      }

      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        await Future.delayed(const Duration(milliseconds: 150));
      }

      final int session = ++_listenSession;
      _finalHandled = false;

      _onResult = onResult;
      _onStateChange = onStateChange;
      _onFinalSentence = onFinalSentence;
      _onErrorTimeout = onErrorTimeout;
      _lastRecognized = '';

      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onError: (error) => _handleSpeechError(error),
          onStatus: (status) => _handleSpeechStatus(status),
        );
      }

      if (_isSpeechInitialized) {
        _isListening = true;
        _onStateChange?.call(true);
        await _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            pauseFor: const Duration(seconds: 10),
            listenFor: const Duration(minutes: 5),
            cancelOnError: false,
            partialResults: true,
            localeId: 'id_ID',
          ),
          onSoundLevelChange: (level) {
            if (session != _listenSession) return;
            onSoundLevel?.call(level);
          },
          onResult: (val) {
            if (session != _listenSession) return;
            _lastRecognized = val.recognizedWords;
            _onResult?.call(val.recognizedWords);
          },
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      _onStateChange?.call(false);
      return false;
    } finally {
      _startListeningInFlight = false;
    }
  }

  Future<void> stopListening() async {
    _listenSession++;
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _onStateChange?.call(false);
    }
  }

  Future<void> speak(
    String text, {
    VoidCallback? onComplete,
  }) async {
    if (text.isEmpty) return;

    await init();

    if (_isListening) {
      await stopListening();
    }

    final int session = ++_speakSession;

    await _tts.stop();
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);

    var langResult = await _tts.setLanguage('id-ID');
    if (langResult != 1) {
      await _tts.setLanguage('id_ID');
    }

    _isSpeaking = true;
    onTtsDone = onComplete;

    final cleanText = text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'#+'), '')
        .replaceAll(RegExp(r'~+'), '')
        .replaceAll(RegExp(r'\/'), ' per ')
        .replaceAll(RegExp(r'\+'), ' tambah ')
        .replaceAll(RegExp(r'\-'), ' kurang ')
        .replaceAll(RegExp(r'\='), ' sama dengan ')
        .replaceAll(RegExp(r'\n+'), '. ');

    debugPrint('TTS Speaking text: $cleanText');

    final result = await _tts.speak(cleanText);
    debugPrint('TTS Speak result code: $result');

    if (result != 1 && session == _speakSession) {
      _isSpeaking = false;
      final cb = onTtsDone;
      onTtsDone = null;
      cb?.call();
    }
  }

  Future<void> stopSpeaking() async {
    _speakSession++;
    onTtsDone = null;
    await _tts.stop();
    _isSpeaking = false;
  }
}