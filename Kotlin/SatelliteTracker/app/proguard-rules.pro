# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Predict4Java - keep all classes for TLE calculations
-keep class com.github.amsacode.predict4java.** { *; }
-keep class uk.me.g4dpz.satellite.** { *; }

# Yandex MapKit
-keep class com.yandex.mapkit.** { *; }
-keep class com.yandex.runtime.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
