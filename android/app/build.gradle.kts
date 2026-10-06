import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: dipakai bila android/key.properties ada (file ini di-gitignore,
// tidak pernah di-commit). Tanpa file itu, build release jatuh ke debug signing
// agar `flutter run --release` dan CI tetap jalan.
val keystoreProps = Properties()
val keystorePropsFile = rootProject.file("key.properties")
if (keystorePropsFile.exists()) {
    keystoreProps.load(FileInputStream(keystorePropsFile))
}

android {
    namespace = "com.kasirquh.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // WAJIB: flutter_local_notifications butuh core library desugaring
        // (checkDebugAarMetadata gagal tanpa ini). Bukan tambal sulam —
        // konfigurasi resmi dari dokumentasi plugin & Android.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kasirquh.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("rilis") {
            if (keystorePropsFile.exists()) {
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                storeType = keystoreProps["storeType"] as String? ?: "pkcs12"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropsFile.exists()) {
                signingConfigs.getByName("rilis")
            } else {
                // Tanpa key.properties (mis. CI): pakai debug key agar build tetap jalan.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Pasangan dari isCoreLibraryDesugaringEnabled di atas.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
