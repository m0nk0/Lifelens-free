# ===========================================
# TensorFlow Lite keep rules
# ===========================================

# Keep TFLite core classes (needed for reflection)
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.experimental.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.task.** { *; }

# Keep native methods (JNI)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter embedding classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep camera classes
-keep class io.flutter.plugins.camera.** { *; }

# ===========================================
# General rules
# ===========================================

# Don't warn about missing optional dependencies
-dontwarn org.tensorflow.lite.experimental.**
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn com.google.mlkit.**

# Keep classes referenced by name (reflection)
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}