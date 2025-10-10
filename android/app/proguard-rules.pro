# Mantener clases de Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Mantener clases de Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Mantener modelos de datos usados con Firestore
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Evitar advertencias de Gson
-dontwarn sun.misc.**
