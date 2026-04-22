1. Modify `CountdownAudioHandler` to set `handleAudioSession: false` in `AudioPlayer`.
2. Move `session.setActive(true)` to `play()` and `startForTarget()` instead of just `init()`.
3. Use `AudioSource.asset()` directly instead of `_getPhysicalAudioFile()`.
4. Switch `AudioSession` back to `music()`.
