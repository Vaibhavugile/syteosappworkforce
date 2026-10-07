import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    id("kotlin-android")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ============================================================
// RELEASE KEYSTORE CONFIGURATION
// ============================================================

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ==========================================================
    // APP ID
    // ==========================================================

    namespace = "com.syteoslabs.business"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ==========================================================
    // JAVA / KOTLIN
    // ==========================================================

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ==========================================================
    // DEFAULT CONFIG
    // ==========================================================

    defaultConfig {
        applicationId = "com.syteoslabs.business"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ==========================================================
    // SIGNING CONFIGURATION
    // ==========================================================

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(
                    keystoreProperties["storeFile"] as String
                )
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // ==========================================================
    // BUILD TYPES
    // ==========================================================

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // Keep release optimized for production.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// ============================================================
// FLUTTER
// ============================================================

flutter {
    source = "../.."
}