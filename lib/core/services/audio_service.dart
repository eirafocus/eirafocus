import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.5;
  String? _currentSound;

  AudioService._();

  double get volume => _volume;
  String? get currentSound => _currentSound;

  static const List<String> availableSounds = ['Rain', 'Forest', 'Creek', 'Bell'];

  Future<void> play(String soundName) async {
    await stop();
    _currentSound = soundName;

    final wavBytes = _generateAmbientWav(soundName);
    await _player.setSource(BytesSource(wavBytes));
    await _player.setVolume(_volume);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.resume();
  }

  Future<void> stop() async {
    _currentSound = null;
    await _player.stop();
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  void dispose() {
    _player.dispose();
  }

  Uint8List _generateAmbientWav(String type) {
    const sampleRate = 22050;
    const durationSec = 4;
    const numSamples = sampleRate * durationSec;
    final rng = math.Random(type.hashCode);

    final samples = Int16List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      double val = 0;

      switch (type) {
        case 'Rain':
          val = (rng.nextDouble() * 2 - 1) * 0.3;
          if (i > 0) val = samples[i - 1] / 32768.0 * 0.7 + val * 0.3;
          break;
        case 'Forest':
          val = (rng.nextDouble() * 2 - 1) * 0.15;
          if (i > 0) val = samples[i - 1] / 32768.0 * 0.85 + val * 0.15;
          val += math.sin(2 * math.pi * 220 * t) * 0.02 * math.sin(2 * math.pi * 0.5 * t);
          break;
        case 'Creek':
          val = (rng.nextDouble() * 2 - 1) * 0.2;
          if (i > 0) val = samples[i - 1] / 32768.0 * 0.8 + val * 0.2;
          val += math.sin(2 * math.pi * (300 + 100 * math.sin(2 * math.pi * 2.5 * t)) * t) * 0.04;
          break;
        case 'Bell':
          double phase = (t % 2.0) / 2.0;
          double decay = (1 - phase) * (1 - phase);
          val = math.sin(2 * math.pi * 528 * t) * decay * 0.2;
          val += math.sin(2 * math.pi * 1056 * t) * decay * 0.08;
          break;
        default:
          val = 0;
      }

      samples[i] = (val.clamp(-1.0, 1.0) * 32000).toInt();
    }

    return _encodeWav(samples, sampleRate);
  }

  Uint8List _encodeWav(Int16List samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final fileSize = 44 + dataSize;
    final buffer = ByteData(fileSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize - 8, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // (space)
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
