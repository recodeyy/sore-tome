# Flutter / Dart — keep embedding & plugin entry points.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase / Google Play services (FCM, Auth) — referenced via reflection.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep annotations and signatures used by JSON/reflection.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Play Core / Flutter deferred components — referenced by the Flutter embedding
# but only present when Play Feature Delivery is used. Not used by this app, so
# silence R8's missing-class errors and keep the Flutter Play Store shims.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
