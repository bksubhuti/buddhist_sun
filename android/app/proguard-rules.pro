# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods and JNI
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep Flutter generated classes
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$ViewDestroyListener { *; }

# Google Maps Flutter
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.maps.**

# Audio & Notifications
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.**
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.** { *; }

# Flutter Volume Controller
-keep class com.yosemiteyss.flutter_volume_controller.** { *; }
-dontwarn com.yosemiteyss.flutter_volume_controller.**

# Vibration
-keep class com.benjaminabel.vibration.** { *; }
-dontwarn com.benjaminabel.vibration.**

# Wakelock Plus
-keep class dev.fluttercommunity.plus.wakelock.** { *; }
-dontwarn dev.fluttercommunity.plus.wakelock.**

# Package Info Plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-dontwarn dev.fluttercommunity.plus.packageinfo.**

# Geolocator & Geocoding
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**
-keep class com.baseflow.geocoding.** { *; }
-dontwarn com.baseflow.geocoding.**

# Flutter Compass
-keep class com.hemanthraj.fluttercompass.** { *; }
-dontwarn com.hemanthraj.fluttercompass.**

# Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# Sqflite
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Play Core & Flutter Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
