import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bandpassrecords.dpm"
    // Use SDK 36 as required by plugins (audioplayers, file_picker, google_sign_in, etc.)
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    
    // Suprimir warnings de Java 8 de plugins Flutter antigos
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(listOf("-Xlint:-options"))
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bandpassrecords.dpm"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Android 5.0 (Lollipop) - minimum for most apps
        targetSdk = 36  // Android 15 - required by plugins
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // For now, use debug keystore for release builds
            // To use a release keystore, create android/key.properties with:
            // storeFile=path/to/release.keystore
            // storePassword=your_password
            // keyAlias=your_alias
            // keyPassword=your_password
            // Then uncomment the code below and comment out the debug keystore section
            
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
                val keystorePath = keystoreProperties.getProperty("storeFile") ?: ""
                storeFile = rootProject.file(keystorePath)
                storePassword = keystoreProperties.getProperty("storePassword") ?: ""
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            } else {
                // Fallback to debug keystore if key.properties doesn't exist
                storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
            
            // TODO: Uncomment below when you have a release keystore
            // val keystorePropertiesFile = rootProject.file("key.properties")
            // if (keystorePropertiesFile.exists()) {
            //     val keystoreProperties = java.util.Properties()
            //     keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
            //     storeFile = file(keystoreProperties.getProperty("storeFile") ?: "")
            //     storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            //     keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            //     keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            // }
        }
    }

    buildTypes {
        debug {
            // Debug builds use the default debug signing config
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            // ProGuard rules (create proguard-rules.pro if needed)
            val proguardRulesFile = file("proguard-rules.pro")
            if (proguardRulesFile.exists()) {
                proguardFiles(
                    getDefaultProguardFile("proguard-android-optimize.txt"),
                    "proguard-rules.pro"
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for Java 8+ API support
    // Updated to 2.1.4+ as required by flutter_local_notifications 19.5.0
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
