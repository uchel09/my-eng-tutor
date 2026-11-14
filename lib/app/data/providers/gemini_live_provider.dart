import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/gemini_constants.dart';
import '../models/transcript_turn_model.dart';

/// Connection lifecycle states for [GeminiLiveProvider].
enum LiveConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Exception thrown when connecting to or communicating with Gemini Live fails.
class GeminiLiveException implements Exception {
  const GeminiLiveException(this.message);

  final String message;

  @override
  String toString() => 'GeminiLiveException: $message';
}

/// Manages a bidirectional WebSocket session with the Gemini Multimodal Live API.
class GeminiLiveProvider {
  GeminiLiveProvider({
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final WebSocketChannel Function(Uri uri) _channelFactory;

  final StreamController<Uint8List> _audioOutputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<TranscriptTurnModel> _transcriptController =
      StreamController<TranscriptTurnModel>.broadcast();
  final StreamController<void> _interruptedController =
      StreamController<void>.broadcast();
  final StreamController<void> _turnCompleteController =
      StreamController<void>.broadcast();
  final StreamController<LiveConnectionState> _connectionStateController =
      StreamController<LiveConnectionState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Completer<void>? _setupCompleter;
  LiveConnectionState _currentState = LiveConnectionState.disconnected;
  bool _isIntentionalDisconnect = false;
  bool _isDisposed = false;

  /// Current connection state snapshot.
  LiveConnectionState get currentState => _currentState;

  /// Decoded PCM16 24kHz mono audio chunks streamed from Gemini Live.
  Stream<Uint8List> get audioOutputStream => _audioOutputController.stream;

  /// Live input/output transcription turns from user and tutor.
  Stream<TranscriptTurnModel> get transcriptStream =>
      _transcriptController.stream;

  /// Emits whenever the user interrupts the tutor's ongoing audio response.
  Stream<void> get interruptedStream => _interruptedController.stream;

  /// Emits when the tutor finishes its current response turn.
  Stream<void> get turnCompleteStream => _turnCompleteController.stream;

  /// Emits connection state transitions.
  Stream<LiveConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Emits human-readable Indonesian error messages on connection/stream errors.
  Stream<String> get errorStream => _errorController.stream;

  /// Decodes raw WebSocket audio payload JSON messages into a normalized map.
  static Map<String, dynamic>? _decodeJsonMessage(dynamic raw) {
    String? textPayload;
    if (raw is String) {
      textPayload = raw;
    } else if (raw is List<int>) {
      textPayload = utf8.decode(raw, allowMalformed: true);
    }
    if (textPayload == null || textPayload.isEmpty) return null;

    try {
      final decoded = jsonDecode(textPayload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Opens an isolated one-shot Live API WebSocket connection to synthesize
  /// spoken PCM16 24kHz audio for [text] without touching the active Live session.
  Future<Uint8List> synthesizeSpeechOncePcm24k({
    required String apiKey,
    required String model,
    required String text,
    bool slow = false,
    String voiceName = 'Aoede',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiLiveException(
        'API key Gemini belum diatur. Silakan isi API key di Settings.',
      );
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw const GeminiLiveException(
        'Teks untuk sintesis suara tidak boleh kosong.',
      );
    }

    final cleanModel = model.trim().isNotEmpty
        ? model.trim()
        : GeminiConstants.defaultLiveModel;
    final normalizedModel =
        cleanModel.startsWith('models/') ? cleanModel : 'models/$cleanModel';

    final directive = slow
        ? 'You are a strict read-aloud pronunciation engine. Speak ONLY the exact English text sent by the user verbatim, slowly and clearly at a steady learner pace. Do not greet, answer, translate, comment, or add any extra words.'
        : 'You are a strict read-aloud pronunciation engine. Speak ONLY the exact English text sent by the user verbatim in natural American English. Do not greet, answer, translate, comment, or add any extra words.';

    final uri = Uri.parse('${GeminiConstants.liveWsEndpoint}?key=$trimmedKey');
    WebSocketChannel? localChannel;
    StreamSubscription<dynamic>? localSubscription;
    final setupCompleter = Completer<void>();
    final audioCompleter = Completer<Uint8List>();
    // Prevent unhandled async errors if a frame arrives or fails before await attaches.
    unawaited(setupCompleter.future.then<void>((_) {}, onError: (_) {}));
    unawaited(audioCompleter.future.then<void>((_) {}, onError: (_) {}));
    final audioBuilder = BytesBuilder(copy: false);

    void failPending(GeminiLiveException error) {
      if (!setupCompleter.isCompleted) {
        setupCompleter.completeError(error);
      } else if (!audioCompleter.isCompleted) {
        audioCompleter.completeError(error);
      }
    }

    var isReady = false;
    try {
      localChannel = _channelFactory(uri);
      await localChannel.ready.timeout(const Duration(seconds: 5));
      isReady = true;

      localSubscription = localChannel.stream.listen(
        (dynamic raw) {
          final json = _decodeJsonMessage(raw);
          if (json == null) return;

          final rawError = json['error'];
          if (rawError is Map) {
            debugPrint('GeminiLive TTS rawError (model=$cleanModel): $rawError');
            final errMessage =
                rawError['message']?.toString() ??
                'Terjadi gangguan pada Gemini Live.';
            failPending(GeminiLiveException(_mapFriendlyError(errMessage)));
            return;
          }

          if (json.containsKey('setupComplete') &&
              !setupCompleter.isCompleted) {
            setupCompleter.complete();
          }

          final serverContent = json['serverContent'];
          if (serverContent is! Map) return;

          final modelTurn = serverContent['modelTurn'];
          if (modelTurn is Map) {
            final parts = modelTurn['parts'];
            if (parts is List) {
              for (final part in parts) {
                if (part is! Map) continue;
                final inlineData = part['inlineData'];
                if (inlineData is Map) {
                  final mimeType =
                      (inlineData['mimeType'] as String?)?.toLowerCase() ?? '';
                  final data = inlineData['data'] as String?;
                  if (data != null &&
                      data.isNotEmpty &&
                      (mimeType.isEmpty ||
                          mimeType.startsWith('audio/pcm') ||
                          mimeType.contains('codec=pcm'))) {
                    try {
                      audioBuilder.add(base64Decode(data));
                    } catch (_) {
                      // Skip malformed chunk without aborting full turn.
                    }
                  }
                }
              }
            }
          }

          if (serverContent['turnComplete'] == true &&
              !audioCompleter.isCompleted) {
            final bytes = audioBuilder.takeBytes();
            if (bytes.isEmpty) {
              debugPrint(
                'GeminiLive TTS empty audio on turnComplete (model=$cleanModel)',
              );
              audioCompleter.completeError(
                const GeminiLiveException(
                  'Data audio TTS dari Gemini Live kosong.',
                ),
              );
            } else {
              audioCompleter.complete(bytes);
            }
          }
        },
        onError: (Object error) {
          debugPrint('GeminiLive TTS onError (model=$cleanModel): $error');
          failPending(GeminiLiveException(_mapFriendlyError(error)));
        },
        onDone: () {
          final closeCode = localChannel?.closeCode;
          final closeReason = localChannel?.closeReason;
          debugPrint(
            'GeminiLive TTS onDone (model=$cleanModel, closeCode=$closeCode, closeReason=$closeReason)',
          );

          if (!setupCompleter.isCompleted) {
            setupCompleter.completeError(
              GeminiLiveException(_mapFriendlyClose(closeCode, closeReason)),
            );
            return;
          }

          if (!audioCompleter.isCompleted) {
            if (closeCode != null && closeCode != 1000) {
              audioCompleter.completeError(
                GeminiLiveException(_mapFriendlyClose(closeCode, closeReason)),
              );
              return;
            }

            final bytes = audioBuilder.takeBytes();
            if (bytes.isNotEmpty) {
              audioCompleter.complete(bytes);
            } else {
              debugPrint(
                'GeminiLive TTS empty audio onDone (model=$cleanModel, closeCode=$closeCode, closeReason=$closeReason)',
              );
              audioCompleter.completeError(
                const GeminiLiveException(
                  'Data audio TTS dari Gemini Live kosong.',
                ),
              );
            }
          }
        },
        cancelOnError: false,
      );

      final setupPayload = <String, dynamic>{
        'setup': <String, dynamic>{
          'model': normalizedModel,
          'generationConfig': <String, dynamic>{
            'responseModalities': <String>['AUDIO'],
            'speechConfig': <String, dynamic>{
              'voiceConfig': <String, dynamic>{
                'prebuiltVoiceConfig': <String, dynamic>{
                  'voiceName': voiceName,
                },
              },
            },
          },
          'systemInstruction': <String, dynamic>{
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': directive},
            ],
          },
          'inputAudioTranscription': <String, dynamic>{},
          'outputAudioTranscription': <String, dynamic>{},
        },
      };

      localChannel.sink.add(jsonEncode(setupPayload));

      await setupCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Server Gemini Live tidak merespons setup tepat waktu.',
          );
        },
      );

      final textTurnPayload = <String, dynamic>{
        'clientContent': <String, dynamic>{
          'turns': <Map<String, dynamic>>[
            <String, dynamic>{
              'role': 'user',
              'parts': <Map<String, dynamic>>[
                <String, dynamic>{'text': trimmedText},
              ],
            },
          ],
          'turnComplete': true,
        },
      };

      localChannel.sink.add(jsonEncode(textTurnPayload));

      return await audioCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Respons audio TTS dari Gemini Live timeout.',
          );
        },
      );
    } on TimeoutException {
      throw const GeminiLiveException(
        'Koneksi ke Gemini Live timeout. Silakan coba lagi.',
      );
    } on SocketException {
      throw const GeminiLiveException(
        'Tidak dapat terhubung ke internet. Pastikan perangkat terhubung ke jaringan.',
      );
    } on WebSocketChannelException catch (error) {
      throw GeminiLiveException(_mapFriendlyError(error));
    } on GeminiLiveException {
      rethrow;
    } catch (error) {
      throw GeminiLiveException(_mapFriendlyError(error));
    } finally {
      if (localSubscription != null) {
        try {
          await localSubscription
              .cancel()
              .then<void>((_) {}, onError: (Object _) {})
              .timeout(const Duration(milliseconds: 400), onTimeout: () {});
        } catch (_) {
          // Ignore subscription cancel errors after one-shot synthesis.
        }
      }
      if (localChannel != null) {
        try {
          final closeFuture = localChannel.sink
              .close()
              .then<void>((_) {}, onError: (Object _) {});
          if (!isReady) {
            unawaited(closeFuture);
          } else {
            await closeFuture.timeout(
              const Duration(milliseconds: 500),
              onTimeout: () {},
            );
          }
        } catch (_) {
          // Ignore close errors after one-shot synthesis completes or fails.
        }
      }
    }
  }

  /// Opens a Gemini Live WebSocket session and waits for `setupComplete`.
  Future<void> connect({
    required String apiKey,
    required String model,
    required String systemInstruction,
    String voiceName = 'Aoede',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      const msg =
          'API key Gemini belum diatur. Silakan isi API key di Settings.';
      _emitError(msg);
      _setState(LiveConnectionState.error);
      throw const GeminiLiveException(msg);
    }

    await disconnect();
    _isIntentionalDisconnect = false;
    _setState(LiveConnectionState.connecting);

    final uri = Uri.parse('${GeminiConstants.liveWsEndpoint}?key=$trimmedKey');
    final setupCompleter = Completer<void>();
    _setupCompleter = setupCompleter;

    try {
      final channel = _channelFactory(uri);
      _channel = channel;

      await channel.ready.timeout(const Duration(seconds: 15));

      _subscription = channel.stream.listen(
        _handleIncomingMessage,
        onError: _handleStreamError,
        onDone: _handleStreamDone,
        cancelOnError: false,
      );

      final normalizedModel =
          model.startsWith('models/') ? model : 'models/$model';
      final setupPayload = <String, dynamic>{
        'setup': <String, dynamic>{
          'model': normalizedModel,
          'generationConfig': <String, dynamic>{
            'responseModalities': <String>['AUDIO'],
            'speechConfig': <String, dynamic>{
              'voiceConfig': <String, dynamic>{
                'prebuiltVoiceConfig': <String, dynamic>{
                  'voiceName': voiceName,
                },
              },
            },
          },
          'systemInstruction': <String, dynamic>{
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': systemInstruction},
            ],
          },
          'inputAudioTranscription': <String, dynamic>{},
          'outputAudioTranscription': <String, dynamic>{},
        },
      };

      channel.sink.add(jsonEncode(setupPayload));

      await setupCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Server Gemini Live tidak merespons setup tepat waktu.',
          );
        },
      );
    } on TimeoutException {
      const msg =
          'Koneksi ke Gemini Live timeout. Periksa koneksi internet Anda.';
      await _cleanupChannelOnly();
      _emitError(msg);
      _setState(LiveConnectionState.error);
      throw const GeminiLiveException(msg);
    } on SocketException {
      const msg =
          'Tidak ada koneksi internet. Pastikan perangkat terhubung ke jaringan.';
      await _cleanupChannelOnly();
      _emitError(msg);
      _setState(LiveConnectionState.error);
      throw const GeminiLiveException(msg);
    } on WebSocketChannelException catch (error) {
      final friendly = _mapFriendlyError(error);
      await _cleanupChannelOnly();
      _emitError(friendly);
      _setState(LiveConnectionState.error);
      throw GeminiLiveException(friendly);
    } on GeminiLiveException {
      await _cleanupChannelOnly();
      _setState(LiveConnectionState.error);
      rethrow;
    } catch (error) {
      final friendly = _mapFriendlyError(error);
      await _cleanupChannelOnly();
      _emitError(friendly);
      _setState(LiveConnectionState.error);
      throw GeminiLiveException(friendly);
    }
  }

  /// Sends raw PCM16 16kHz mono microphone audio bytes to Gemini Live.
  void sendAudioChunk(Uint8List pcm16kBytes) {
    final channel = _channel;
    if (channel == null ||
        _currentState != LiveConnectionState.connected ||
        pcm16kBytes.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'realtimeInput': <String, dynamic>{
        'mediaChunks': <Map<String, dynamic>>[
          <String, dynamic>{
            'mimeType': 'audio/pcm;rate=${GeminiConstants.inputSampleRate}',
            'data': base64Encode(pcm16kBytes),
          },
        ],
      },
    };
    channel.sink.add(jsonEncode(payload));
  }

  /// Returns the serialized Gemini Live `realtimeInput.audioStreamEnd` JSON frame.
  static String encodeAudioStreamEndPayload() {
    return jsonEncode(<String, dynamic>{
      'realtimeInput': <String, dynamic>{
        'audioStreamEnd': true,
      },
    });
  }

  /// Signals to Gemini Live that the user finished speaking their recorded turn.
  void sendAudioStreamEnd() {
    final channel = _channel;
    if (channel == null || _currentState != LiveConnectionState.connected) {
      return;
    }

    channel.sink.add(encodeAudioStreamEndPayload());
  }

  /// Sends a completed user text turn into the active Live session.
  void sendTextMessage(String text) {
    final channel = _channel;
    final trimmed = text.trim();
    if (channel == null ||
        _currentState != LiveConnectionState.connected ||
        trimmed.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'clientContent': <String, dynamic>{
        'turns': <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'user',
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': trimmed},
            ],
          },
        ],
        'turnComplete': true,
      },
    };
    channel.sink.add(jsonEncode(payload));
  }

  /// Gracefully closes the active WebSocket connection and resets state.
  Future<void> disconnect() async {
    _isIntentionalDisconnect = true;
    await _cleanupChannelOnly();
    _setState(LiveConnectionState.disconnected);
  }

  /// Permanently closes the provider and all broadcast streams.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await disconnect();
    await _audioOutputController.close();
    await _transcriptController.close();
    await _interruptedController.close();
    await _turnCompleteController.close();
    await _connectionStateController.close();
    await _errorController.close();
  }

  Future<void> _cleanupChannelOnly() async {
    final completer = _setupCompleter;
    _setupCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        const GeminiLiveException('Koneksi Gemini Live ditutup sebelum siap.'),
      );
    }

    await _subscription?.cancel();
    _subscription = null;

    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await channel.sink.close();
      } catch (_) {
        // Ignore close errors when tearing down an already broken socket.
      }
    }
  }

  void _handleIncomingMessage(dynamic raw) {
    if (_isDisposed) return;

    String? textPayload;
    if (raw is String) {
      textPayload = raw;
    } else if (raw is List<int>) {
      textPayload = utf8.decode(raw, allowMalformed: true);
    }
    if (textPayload == null || textPayload.isEmpty) return;

    dynamic decoded;
    try {
      decoded = jsonDecode(textPayload);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    final json = Map<String, dynamic>.from(decoded);

    if (json.containsKey('setupComplete')) {
      final completer = _setupCompleter;
      if (completer != null && !completer.isCompleted) {
        _setState(LiveConnectionState.connected);
        completer.complete();
      }
    }

    final rawError = json['error'];
    if (rawError is Map) {
      final errMessage =
          rawError['message']?.toString() ?? 'Terjadi gangguan pada Gemini Live.';
      final friendly = _mapFriendlyError(errMessage);
      _emitError(friendly);
      _setState(LiveConnectionState.error);
      final completer = _setupCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.completeError(GeminiLiveException(friendly));
      }
    }

    final serverContent = json['serverContent'];
    if (serverContent is! Map) return;

    if (serverContent['interrupted'] == true &&
        !_interruptedController.isClosed) {
      _interruptedController.add(null);
    }

    final inputTranscription = serverContent['inputTranscription'];
    if (inputTranscription is Map) {
      final text = (inputTranscription['text'] as String?) ?? '';
      if (text.trim().isNotEmpty && !_transcriptController.isClosed) {
        _transcriptController.add(
          TranscriptTurnModel(
            role: 'user',
            text: text,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    final outputTranscription = serverContent['outputTranscription'];
    if (outputTranscription is Map) {
      final text = (outputTranscription['text'] as String?) ?? '';
      if (text.trim().isNotEmpty && !_transcriptController.isClosed) {
        _transcriptController.add(
          TranscriptTurnModel(
            role: 'tutor',
            text: text,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    final modelTurn = serverContent['modelTurn'];
    if (modelTurn is Map) {
      final parts = modelTurn['parts'];
      if (parts is List) {
        for (final part in parts) {
          if (part is! Map) continue;
          final inlineData = part['inlineData'];
          if (inlineData is Map) {
            final mimeType =
                (inlineData['mimeType'] as String?)?.toLowerCase() ?? '';
            final data = inlineData['data'] as String?;
            if (mimeType.startsWith('audio/pcm') &&
                data != null &&
                data.isNotEmpty &&
                !_audioOutputController.isClosed) {
              try {
                _audioOutputController.add(base64Decode(data));
              } catch (_) {
                // Skip malformed audio frame without crashing the session.
              }
            }
          }

          final partText = part['text'] as String?;
          final isThought = part['thought'] == true;
          if (!isThought &&
              partText != null &&
              partText.trim().isNotEmpty &&
              !_transcriptController.isClosed) {
            _transcriptController.add(
              TranscriptTurnModel(
                role: 'tutor',
                text: partText,
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      }
    }

    if (serverContent['turnComplete'] == true &&
        !_turnCompleteController.isClosed) {
      _turnCompleteController.add(null);
    }
  }

  void _handleStreamError(Object error) {
    if (_isDisposed || _isIntentionalDisconnect) return;
    final friendly = _mapFriendlyError(error);
    _emitError(friendly);
    _setState(LiveConnectionState.error);

    final completer = _setupCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(GeminiLiveException(friendly));
    }
  }

  void _handleStreamDone() {
    if (_isDisposed) return;
    if (_isIntentionalDisconnect) {
      _setState(LiveConnectionState.disconnected);
      return;
    }

    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason;
    final completer = _setupCompleter;
    if (completer != null && !completer.isCompleted) {
      final friendly = _mapFriendlyClose(closeCode, closeReason);
      _emitError(friendly);
      _setState(LiveConnectionState.error);
      completer.completeError(GeminiLiveException(friendly));
      return;
    }

    if (closeCode != null && closeCode != 1000) {
      _emitError(_mapFriendlyClose(closeCode, closeReason));
      _setState(LiveConnectionState.error);
    } else {
      _setState(LiveConnectionState.disconnected);
    }
  }

  String _mapFriendlyClose(int? code, String? reason) {
    final trimmedReason = (reason ?? '').trim();
    final lower = trimmedReason.toLowerCase();
    if (lower.contains('not found') ||
        lower.contains('unsupported') ||
        lower.contains('invalid model') ||
        (lower.contains('invalid') &&
            !lower.contains('api key') &&
            !lower.contains('key'))) {
      return code != null
          ? 'Sesi Gemini Live ditolak (kode $code): $trimmedReason'
          : 'Sesi Gemini Live ditolak: $trimmedReason';
    }
    if (lower.contains('quota') ||
        lower.contains('rate') ||
        lower.contains('resource_exhausted') ||
        lower.contains('resource exhausted') ||
        lower.contains('429')) {
      return 'Kuota Free Tier Gemini Live sedang penuh. Tunggu sebentar lalu coba lagi.';
    }
    if (lower.contains('api key') ||
        lower.contains('unauthenticated') ||
        lower.contains('permission_denied') ||
        lower.contains('401') ||
        lower.contains('403')) {
      return 'API key Gemini tidak valid atau belum memiliki izin Live API.';
    }
    if (code == 1008) {
      if (trimmedReason.isNotEmpty) {
        return 'Sesi Gemini Live ditolak (kode 1008): $trimmedReason';
      }
      return 'Koneksi Gemini Live terputus (API key tidak valid atau kuota Free Tier penuh).';
    }
    if (trimmedReason.isNotEmpty) {
      return 'Sesi Gemini Live terputus: $trimmedReason';
    }
    return 'Koneksi ke Gemini Live terputus. Silakan coba sambungkan ulang.';
  }

  String _mapFriendlyError(Object error) {
    final rawMessage = error.toString().trim();
    final text = rawMessage.toLowerCase();
    if (text.contains('401') ||
        text.contains('403') ||
        text.contains('api key') ||
        text.contains('permission_denied') ||
        text.contains('unauthenticated')) {
      return 'API key Gemini tidak valid atau belum memiliki izin Live API.';
    }
    if (text.contains('429') ||
        text.contains('quota') ||
        text.contains('resource_exhausted') ||
        text.contains('resource exhausted') ||
        text.contains('rate limit')) {
      return 'Kuota Free Tier Gemini Live sedang penuh. Tunggu sebentar lalu coba lagi.';
    }
    if (text.contains('not found') ||
        text.contains('unsupported') ||
        text.contains('ditolak')) {
      return 'Sesi Gemini Live ditolak: $rawMessage';
    }
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network')) {
      return 'Tidak dapat terhubung ke internet. Periksa koneksi jaringan Anda.';
    }
    if (text.contains('timeout')) {
      return 'Koneksi ke Gemini Live timeout. Silakan coba lagi.';
    }
    return 'Gangguan koneksi Gemini Live. Periksa API key, model, dan internet Anda.';
  }

  void _setState(LiveConnectionState next) {
    _currentState = next;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(next);
    }
  }

  void _emitError(String message) {
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }
}
