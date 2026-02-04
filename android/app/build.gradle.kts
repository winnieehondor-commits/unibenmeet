plugins {
    id("com.android.application")
    // Applies the Google Services plugin to connect to Firebase
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Ensure this matches your package name in the Firebase Console
    namespace = "com.example.ludo1" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.ludo1"
        
        // Setting these manually prevents conflicts and ensures Firebase compatibility
        minSdk = 21
        targetSdk = 33
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Using debug keys for now so "flutter run --release" works without setup
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM (Bill of Materials) to manage versioning easily
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
}