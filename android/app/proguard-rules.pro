# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Kotlin Coroutines & Serialization
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Supabase / GoTrue / Postgrest / Storage
-keep class com.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**

# Netty & HTTP
-dontwarn io.ktor.**
-dontwarn okio.**
-dontwarn okhttp3.**

# Suppress ProGuard Warnings for unused Android architecture components
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
-dontwarn androidx.**
