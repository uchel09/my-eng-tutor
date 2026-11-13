import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:my_english_tutor/app/data/services/audio_service.dart';

void main() {
  test('buildWavFromPcm16 writes a valid 44-byte RIFF/WAVE header', () {
    final pcmBytes = Uint8List.fromList(<int>[0x01, 0x00, 0xFE, 0xFF, 0x10, 0x20]);
    final wav = buildWavFromPcm16(
      pcmBytes: pcmBytes,
      sampleRate: 16000,
      channels: 1,
    );

    expect(wav.length, equals(44 + pcmBytes.length));

    expect(ascii.decode(wav.sublist(0, 4)), equals('RIFF'));
    expect(ascii.decode(wav.sublist(8, 12)), equals('WAVE'));
    expect(ascii.decode(wav.sublist(12, 16)), equals('fmt '));
    expect(ascii.decode(wav.sublist(36, 40)), equals('data'));

    final view = ByteData.view(wav.buffer);
    expect(view.getUint32(4, Endian.little), equals(36 + pcmBytes.length));
    expect(view.getUint32(16, Endian.little), equals(16)); // PCM subchunk size
    expect(view.getUint16(20, Endian.little), equals(1)); // PCM format
    expect(view.getUint16(22, Endian.little), equals(1)); // Mono channel
    expect(view.getUint32(24, Endian.little), equals(16000)); // Sample rate
    expect(view.getUint32(28, Endian.little), equals(32000)); // Byte rate
    expect(view.getUint16(32, Endian.little), equals(2)); // Block align
    expect(view.getUint16(34, Endian.little), equals(16)); // Bits per sample
    expect(view.getUint32(40, Endian.little), equals(pcmBytes.length));

    expect(wav.sublist(44), equals(pcmBytes));
  });
}
