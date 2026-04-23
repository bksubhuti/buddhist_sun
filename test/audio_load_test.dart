import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  testWidgets('Test loading audio via asset uri', (tester) async {
    final player = AudioPlayer();
    try {
      await player.setAudioSource(
        AudioSource.uri(Uri.parse('asset:///assets/audio/timer_countdown_120_en.m4a')),
      );
      print("SUCCESS");
    } catch (e) {
      print("ERROR: $e");
    }
  });
}
