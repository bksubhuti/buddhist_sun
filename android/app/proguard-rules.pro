# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

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
-dontwarn com.ryanheise.just_audio.**
-dontwarn com.dexterous.flutterlocalnotifications.**

# Play Core & Flutter Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

