plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Debe ir al final
}

android {
    namespace = "com.appsevilla.planlive"
    compileSdk = 35 // Usa 33 si estás apuntando a dispositivos comunes, 34+ si es seguro

    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.appsevilla.planlive"
        minSdk = 25 // Firebase y Flutter funcionan bien desde aquí
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // ⚠️ Usa tu propio signing config en producción
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false // Solo activa esto si usas minifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Para soporte de Java 8+ APIs (desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
