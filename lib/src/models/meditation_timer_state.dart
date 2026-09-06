enum MeditationTimerMode {
  timed,
  endAt,
  unlimited,
}

enum MeditationTimerStatus {
  idle,
  delaying,
  running,
  paused,
  completed,
}

class MeditationSoundItem {
  final String id;
  final String displayName;
  final String? assetPath;

  const MeditationSoundItem({
    required this.id,
    required this.displayName,
    this.assetPath,
  });

  static const MeditationSoundItem none = MeditationSoundItem(
    id: 'none',
    displayName: 'None',
    assetPath: null,
  );

  static const MeditationSoundItem vibration = MeditationSoundItem(
    id: 'vibration',
    displayName: 'Vibration Only',
    assetPath: null,
  );

  bool get isNone => id == 'none';
  bool get isVibration => id == 'vibration';

  static const List<MeditationSoundItem> allSounds = [
    none,
    vibration,
    MeditationSoundItem(
      id: 'Bell',
      displayName: 'Bicycle',
      assetPath: 'assets/audio/meditation_sounds/Bell.wav',
    ),
    MeditationSoundItem(
      id: 'CalmBell',
      displayName: 'Suno Chung Chime',
      assetPath: 'assets/audio/meditation_sounds/suno-Calm-Bell.mp3',
    ),
    MeditationSoundItem(
      id: 'SingleBell',
      displayName: 'Suno Calm Bell',
      assetPath: 'assets/audio/meditation_sounds/suno-Single-Bell.mp3',
    ),
    MeditationSoundItem(
      id: 'ZenBell',
      displayName: 'Zen Bell',
      assetPath:
          'assets/audio/meditation_sounds/soundreality-bell-fx-410608.mp3',
    ),
    MeditationSoundItem(
      id: 'SingingBell',
      displayName: 'Singing Bell',
      assetPath:
          'assets/audio/meditation_sounds/freesound_community-singing-bell-hit-2-75258.mp3',
    ),
    MeditationSoundItem(
      id: 'MindfulResonance',
      displayName: 'Mindful Resonance',
      assetPath:
          'assets/audio/meditation_sounds/soundreality-cinematic-bell-519608.mp3',
    ),
    MeditationSoundItem(
      id: 'ClearBell',
      displayName: 'Ding Bell',
      assetPath:
          'assets/audio/meditation_sounds/dragon-studio-bell-ring-390294.mp3',
    ),
    MeditationSoundItem(
      id: 'BronzeBell',
      displayName: 'Church Bell',
      assetPath:
          'assets/audio/meditation_sounds/freesound_community-old-church-bell-6298.mp3',
    ),
    MeditationSoundItem(
      id: 'TempleChimes',
      displayName: 'Temple Chimes',
      assetPath:
          'assets/audio/meditation_sounds/freesound_community-bells-1-72261.mp3',
    ),
    MeditationSoundItem(
      id: 'DeepBellLow',
      displayName: 'Deep Bell (Low)',
      assetPath:
          'assets/audio/meditation_sounds/floraphonic-deep-meditation-bell-hit-root-chakra-1-174455.mp3',
    ),
    MeditationSoundItem(
      id: 'DeepBellWarm',
      displayName: 'Deep Bell (Warm)',
      assetPath:
          'assets/audio/meditation_sounds/floraphonic-deep-meditation-bell-hit-heart-chakra-4-186970.mp3',
    ),
    MeditationSoundItem(
      id: 'DeepBellClear',
      displayName: 'Deep Bell (Clear)',
      assetPath:
          'assets/audio/meditation_sounds/floraphonic-deep-meditation-bell-hit-throat-chakra-5-186971.mp3',
    ),
    MeditationSoundItem(
      id: 'DeepBellBright',
      displayName: 'Deep Bell (Bright)',
      assetPath:
          'assets/audio/meditation_sounds/floraphonic-deep-meditation-bell-hit-third-eye-chakra-6-186972.mp3',
    ),
    MeditationSoundItem(
      id: 'DeepBellPure',
      displayName: 'Deep Bell (Pure)',
      assetPath:
          'assets/audio/meditation_sounds/floraphonic-deep-meditation-bell-hit-crown-chakra-7-186973.mp3',
    ),
    MeditationSoundItem(
      id: 'Bowl',
      displayName: 'Bowl',
      assetPath: 'assets/audio/meditation_sounds/Bowl-fade.wav',
    ),
    MeditationSoundItem(
      id: 'BowlSlow',
      displayName: 'Bowl (Slow)',
      assetPath: 'assets/audio/meditation_sounds/Bowl-slow-fade-.wav',
    ),
    MeditationSoundItem(
      id: 'BowlStrong',
      displayName: 'Deep Bowl',
      assetPath: 'assets/audio/meditation_sounds/BowlStrong.wav',
    ),
    MeditationSoundItem(
      id: 'ThreeBowl',
      displayName: 'Three Bowls',
      assetPath: 'assets/audio/meditation_sounds/ThreeBowl.wav',
    ),
    MeditationSoundItem(
      id: 'Gong',
      displayName: 'Gong',
      assetPath: 'assets/audio/meditation_sounds/Gong-fade.wav',
    ),
    MeditationSoundItem(
      id: 'GongSlow',
      displayName: 'Gong (Slow)',
      assetPath: 'assets/audio/meditation_sounds/Gong-slow-fade.wav',
    ),
    MeditationSoundItem(
      id: 'Sadhu',
      displayName: 'Sadhu',
      assetPath: 'assets/audio/meditation_sounds/Sadhu.wav',
    ),
    MeditationSoundItem(
      id: 'GardenBird',
      displayName: 'Garden Bird',
      assetPath: 'assets/audio/meditation_sounds/GardenBird.wav',
    ),
    MeditationSoundItem(
      id: 'Watch',
      displayName: 'Watch Tick',
      assetPath: 'assets/audio/meditation_sounds/Watch.wav',
    ),
  ];

  static MeditationSoundItem fromId(String id) {
    final search = id.trim().toLowerCase();
    if (search == 'vibration' ||
        search == 'vibration only' ||
        search == 'vibrate') {
      return vibration;
    }
    if (search == 'ding') {
      return allSounds.firstWhere((s) => s.id == 'ClearBell');
    }
    if (search == 'bowlfade' || search == 'bowl (fade)') {
      return allSounds.firstWhere((s) => s.id == 'Bowl');
    }
    if (search == 'bowlslowfade' || search == 'bowl (slow fade)') {
      return allSounds.firstWhere((s) => s.id == 'BowlSlow');
    }
    if (search == 'gongfade' || search == 'gong (fade)') {
      return allSounds.firstWhere((s) => s.id == 'Gong');
    }
    if (search == 'gongslowfade' || search == 'gong (slow fade)') {
      return allSounds.firstWhere((s) => s.id == 'GongSlow');
    }
    return allSounds.firstWhere(
      (s) =>
          s.id.toLowerCase() == search || s.displayName.toLowerCase() == search,
      orElse: () => allSounds.firstWhere(
        (s) => s.id == 'Bowl',
        orElse: () => allSounds.first,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeditationSoundItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
