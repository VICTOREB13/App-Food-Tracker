# Flutter ProGuard Rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# AndroidX Startup
-keep class androidx.startup.** { *; }
-dontwarn androidx.startup.**

# AndroidX WorkManager & Room Database
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.room.**
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }
-dontwarn es.antonborri.home_widget.**

# SQLite & Cryptography
-keep class org.sqlite.** { *; }
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
