plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google services plugin — reads google-services.json
    id("com.google.gms.google-services")
}

import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val isKeystoreConfigured = keystorePropertiesFile.exists()

if (isKeystoreConfigured) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    val isReleaseTask = gradle.startParameter.taskNames.any {
        it.contains("release", ignoreCase = true) || it.contains("bundle") || it.contains("assemble")
    }
    if (isReleaseTask && !gradle.startParameter.taskNames.any { it.contains("debug", ignoreCase = true) }) {
        throw org.gradle.api.GradleException(
            "CRITICAL RELEASE BUILD ERROR: key.properties is missing at sero/android/key.properties! " +
            "Please copy key.properties.example to key.properties and configure your release credentials."
        )
    }
}

android {
    // Must match the package_name in google-services.json
    namespace = "sero.com"
    compileSdk = 35 // Target API level 35 for Android 15
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Must match android_client_info.package_name in google-services.json
        applicationId = "sero.com"
        minSdk = 23 // Standard safe min SDK for modern features
        targetSdk = 35 // Target API level 35 for Android 15
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (isKeystoreConfigured) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (isKeystoreConfigured) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM — manages all Firebase library versions automatically
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Firebase Auth + Firestore + Cloud Messaging (FCM)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
}
