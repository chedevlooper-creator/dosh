import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Yayın imzalama anahtarları android/key.properties dosyasından okunur.
// Bu dosya (ve .jks anahtar deposu) .gitignore'dadır — depoya girmez.
// Yoksa sürüm derlemesi debug anahtarıyla imzalanır, böylece depo
// herkeste derlenir; mağaza yüklemesi için key.properties gereklidir.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dosh.dosh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Mağaza yayını sonrası DEĞİŞTİRİLEMEZ. Kendi alan adınız varsa
        // ilk yüklemeden önce güncelleyin (iOS bundle id ile aynı tutun).
        applicationId = "com.dosh.dosh"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Anahtar deposu yoksa debug ile imzala (yalnız yerel test;
                // bu APK/AAB mağazaya YÜKLENEMEZ).
                signingConfigs.getByName("debug")
            }
            // R8/küçültme bilinçli olarak kapalı: Dart kodu zaten AOT
            // derlenir, kazanç marjinaldir ve eklenti keep-kurallarıyla
            // R8 derlemeyi bozabilir. İstenirse proguard ile açılabilir.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
