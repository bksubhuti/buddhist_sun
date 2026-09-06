# Feature Proposal: 3D Solar Compass, Celestial Path & Monastic Shadow Diagram

**Status:** Proposed / Under Consideration  
**Author:** Bhante Subhūti & Antigravity  
**Target Repository:** `bksubhuti/buddhist_sun`  
**Date:** September 2026  

---

## 1. Executive Summary

This proposal outlines the design and implementation of an interactive **3D Solar Compass, Sun Trajectory Dome, and Dynamic Shadow Simulator** for the *Buddhist Sun* app.

By combining real-time solar positioning algorithms (`nrel_spa`), device magnetometer/gyroscope sensors (`flutter_compass`), and a lightweight native Flutter 3D perspective canvas (`CustomPainter` + `Matrix4`), the app will visually demonstrate:
1. **The Sun's exact position in the sky** (Azimuth bearing and Elevation angle).
2. **The Sun’s diurnal celestial path arc** from dawn to dusk for the current day and season.
3. **A central gnomon (vertical pin) casting a dynamic real-time shadow** across an aligned compass plane.
4. **Traditional Buddhist monastic shadow measurement (*Chāyā*)**, visually illustrating how the shadow shrinks to its minimum length at **Solar Noon (*Majjhantika*)**.

This feature requires **zero heavy 3D game engines**, incurs **zero APK bloat**, and runs smoothly at 60–120 FPS across all Android and iOS devices.

---

## 2. Monastic & Practical Significance (Vinaya Context)

In the Buddhist monastic discipline (Vinaya Piṭaka), the measurement of the sun's shadow (*chāyā*) has been central to daily monastic life for 2,500 years:
* **The Noon Meal Limit (*Kāla* vs. *Vikāla*)**: Monastics must conclude their daily meal before the sun crosses the meridian at solar noon (*majjhantikasamaya*).
* **The Shadow Stick (*Chāyā-yanta*)**: Historically, monasteries marked the ground with stones or used a vertical rod (gnomon) to measure the shadow in "footprints" (*pāda*) or "fingers" (*aṅgula*). As noon approaches, the shadow contracts to its shortest length of the day. Once it begins to lengthen in the opposite direction, solar noon has passed.
* **Modern Synthesis**: While *Buddhist Sun* provides high-precision countdown timers and audio announcements for Solar Noon and Dawn, visualizing the 3D sun arc and gnomon shadow creates an immediate, intuitive, and educational connection between the ancient monastic method and modern astronomical calculation.

---

## 3. Core Feature Specifications

### 3.1 3D Perspective Ground Plane (Compass Dial)
* An elliptical 3D ground disk tilted in perspective showing:
  * Cardinal & Ordinal directions (N, NE, E, SE, S, SW, W, NW).
  * Degree markings (0° to 360°).
  * Target direction needle pointing toward sacred pilgrimage sites (e.g., Mahābodhi Temple at Bodh Gayā, Shwedagon, etc.).
* Aligned in real time to magnetic / true North using the device's compass sensors.

### 3.2 Central Gnomon & Dynamic Cast Shadow
* A 3D vertical brass/gold pin (gnomon) standing in the center of the compass plane.
* **Cast Shadow Polygon**:
  * **Bearing**: Casts directly opposite the Sun's azimuth:
    $$\theta_{\text{shadow}} = (\theta_{\text{sun}} + 180^\circ) \pmod{360^\circ}$$
  * **Length**: Calculated trigonometrically based on solar elevation ($\alpha$) and gnomon height ($h$):
    $$L_{\text{shadow}} = \frac{h}{\tan(\alpha)}$$
  * **Solar Noon Behavior**: The shadow reaches its daily minimum length and aligns perfectly with the true North–South meridian line.
  * **Shadow Ratio Display**: Optionally displays the shadow-to-pin ratio (e.g., `Shadow = 0.42 × Height`) and traditional Vinaya shadow measurements.

### 3.3 3D Celestial Sky Dome & Sun Trajectory Arc
* A translucent hemispherical wireframe dome rising above the compass plane.
* **Daily Sun Path Arc**: A luminous golden curve showing the sun's journey from sunrise through solar noon to sunset.
* **Live Sun Sphere**: A glowing 3D sun marker positioned at the current real-time coordinates:
  * Projected ray lines connecting the sun sphere down to the gnomon.
* **Special Solar Markers**:
  * Dawn / Astronomical / Nautical / Civil Twilight thresholds.
  * Solar Noon apex (highest elevation of the day).
  * Sunset.
* **Seasonal Solstice Curves (Optional)**: Summer Solstice (highest path) and Winter Solstice (lowest path) reference arcs to visualize seasonal shifts.

### 3.4 Interaction & Viewing Modes
1. **Live Compass Tracking Mode (Default)**:
   * Uses device orientation sensors.
   * Pointing the phone toward the horizon aligns the 3D diagram with the physical world; pointing toward the physical sun lines up with the virtual sun marker.
2. **Interactive Time Scrubber Mode**:
   * A clean slider at the bottom of the screen allows users to scrub the time from 04:00 to 20:00.
   * As the user drags the slider, the sun sweeps smoothly across the 3D arc, and the shadow realistically rotates and lengthens/shrinks in real time.
   * A "Return to Now" button snaps back to live time.
3. **Touch Orbit Mode**:
   * Users can touch and drag to orbit around the 3D diagram (adjust tilt elevation and azimuth rotation) to inspect the shadow from any perspective.

---

## 4. Visual Concept Wireframe

```
                     ☀️ SUN (Elevation: 48.5°, Azimuth: 138.2° SE)
                    / \
                   /   \  [ Celestial Sun Path Arc ]
                  /     \
                 /       \
      North     /         \
        \      /           \
         \    .             .
          \  /               \
           |/     Gnomon      \
      W----+-----[|]-----------+----E
            \      \          /
             \      \====>   /   [ Dynamic Cast Shadow pointing NW ]
              \             /
               \           /
                 \       /
                   South
```

---

## 5. Technical Architecture & Implementation

### 5.1 Astronomical Mathematics
The app already integrates `nrel_spa: ^1.0.1` in `lib/src/services/solar_calc.dart`. The required calculations are already supported:
1. **Azimuth ($\theta$)**: Degrees clockwise from North ($0^\circ = \text{North}, 90^\circ = \text{East}, 180^\circ = \text{South}, 270^\circ = \text{West}$).
2. **Zenith ($z$) / Elevation ($\alpha$)**: $\alpha = 90^\circ - z$.
3. **Diurnal Path Sampling**: Sampling 24 to 48 points across the day computes the complete spline for the celestial arc in $<1\text{ ms}$.

### 5.2 Lightweight Native 3D Rendering (No Game Engines)
Instead of importing heavy OpenGL/Unity/Filament packages (which increase APK size by 20–40 MB and trigger ProGuard issues), this feature will use Flutter’s built-in **3D Perspective Canvas**:
* **`CustomPainter` with 3D Matrix Transforms**:
  ```dart
  final matrix = Matrix4.identity()
    ..setEntry(3, 2, 0.0015) // Perspective distortion
    ..rotateX(tiltAngle)     // Pitch (viewing angle)
    ..rotateZ(headingAngle); // Compass yaw rotation
  ```
* **Projection Pipeline**:
  1. Define 3D points $(X, Y, Z)$ in world space (where $Z$ is altitude/elevation).
  2. Transform points using `matrix.transform3(Vector3(x, y, z))`.
  3. Render 2D projected coordinates to the `Canvas` with standard Flutter `Path`, `Paint`, and gradient shaders.
* **Benefits**:
  * **0 MB** added to the APK bundle.
  * Native 60 / 120 FPS performance on all devices.
  * Zero third-party dependency maintenance risk.
  * Completely safe with Android ProGuard / R8 minification.

---

## 6. UI / UX Integration Options

### Option A: View Mode in Existing Compass Page (`lib/views/compass_page.dart`)
* Add a 3-way toggle in the AppBar or floating control bar:
  * `[Compass Dial]` | `[Map View]` | `[3D Solar / Shadow]`
* Seamlessly complements the existing compass and pilgrimage direction features.

### Option B: Expandable Card / View in Main Countdown View
* Add an interactive 3D solar widget beneath or alongside the Solar Noon Countdown circle on the home screen.
* Tapping expands into full-screen 3D interactive mode.

---

## 7. Implementation Roadmap

| Phase | Milestone | Estimated Effort |
| :--- | :--- | :--- |
| **Phase 1** | **Solar Math & Shadow Service**<br>Extend `solar_calc.dart` to output real-time azimuth, elevation, shadow vector, and day-arc curve points. | 0.5 day |
| **Phase 2** | **3D Canvas & Ground Projection**<br>Implement `SolarCompassPainter` using `Matrix4` perspective projection. Draw compass ground disc, gnomon, and dynamic shadow. | 1.0 day |
| **Phase 3** | **Celestial Dome & Arc Visualization**<br>Render 3D sun path trajectory, glowing sun sphere, and dawn/noon/dusk threshold markers. | 0.5 day |
| **Phase 4** | **Sensors & Time Scrubber Integration**<br>Connect `FlutterCompass` streams for real-time tracking. Add interactive time slider and touch orbit controls. | 1.0 day |
| **Phase 5** | **Testing, Vinaya Annotations & Polish**<br>Unit tests, Vinaya shadow ratio readout, UI localized strings, and performance profiling. | 0.5 day |

**Total Estimated Effort:** ~3 to 3.5 days.

---

## 8. Conclusion

This feature will elevate *Buddhist Sun* by providing a visually stunning, astronomically accurate, and spiritually relevant tool that directly bridges ancient Buddhist monastic shadow traditions with modern mobile technology.
