plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.devchris06.expensetracker.flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.devchris06.expensetracker.flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Clé debug partagée, écrite par la CI depuis le secret
    // DEBUG_KEYSTORE_BASE64 (fichier ignoré par git). On la référence
    // explicitement : la clé debug "par défaut" dépend du HOME de la
    // machine et n'est pas forcément la même d'un runner à l'autre.
    val sharedKeystore = file("shared-debug.keystore")
    signingConfigs {
        create("shared") {
            storeFile = sharedKeystore
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // Comme pour Loady : signé avec la clé partagée pour que chaque
            // APK s'installe par-dessus le précédent sur le téléphone. En
            // local, sans le fichier, on retombe sur la clé debug de la machine.
            signingConfig = if (sharedKeystore.exists()) {
                signingConfigs.getByName("shared")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
