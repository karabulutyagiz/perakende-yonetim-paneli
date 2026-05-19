import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — key.properties varsa kullanılır (CI / lokal release build).
// Yoksa debug keystore'a düşülür (development / hızlı APK çıkarma).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseSigning = keystorePropertiesFile.exists()

gradle.taskGraph.whenReady {
    val isReleaseBuild = allTasks.any { task ->
        task.name in listOf("assembleRelease", "bundleRelease", "packageRelease")
    }
    if (isReleaseBuild && !hasReleaseSigning) {
        throw GradleException(
            "Release build icin android/key.properties ve release keystore gerekli. " +
                "Debug imzali release uretilmesi engellendi."
        )
    }
}

android {
    namespace = "com.parasende.app"
    compileSdk = flutter.compileSdkVersion
    // Plugin'ler 27.0.12077973 talep ediyor; en yükseğe set et (geriye uyumlu).
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.parasende.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
