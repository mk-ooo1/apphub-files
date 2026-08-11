# 1. Global Attributes
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-keepattributes SourceFile, LineNumberTable

# 2. Flutter Local Notifications (Keep Everything)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# 3. GSON (The most aggressive rules to prevent TypeToken crash)
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements com.google.gson.TypeAdapterFactory
-keep public class * implements com.google.gson.JsonSerializer
-keep public class * implements com.google.gson.JsonDeserializer

# 4. Keep all Enums (Serialized as names)
-keepclassmembers enum * { *; }

# 5. Firebase
-keep class com.google.firebase.** { *; }
-keepclassmembers class com.google.firebase.** { *; }

# 6. General Flutter & Android
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.MKDevOps.moneyManage.** { *; }

# 7. Preserve Resources for dynamic lookup
-keep class **.R$* { *; }

# 8. Expert Fix: Explicitly keep mipmap resources for notifications
-keepclassmembers class **.R$mipmap {
    public static <fields>;
}
-keepclassmembers class **.R$drawable {
    public static <fields>;
}
-keepclassmembers class **.R$raw {
    public static <fields>;
}

# 8. Flutter Local Notifications Receivers
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep public class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
-keep public class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
-keep public class com.dexterous.flutterlocalnotifications.NotificationReceiver
