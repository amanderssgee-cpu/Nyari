import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nyari.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Java 17 / Kotlin 17 target
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.nyari.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // ---- SIGNING (correct paths + null-safe) ----
    val props = Properties()
    val propsFile = rootProject.file("key.properties")   // <-- FIX: look in android/key.properties
    val haveKey = propsFile.exists()

    if (haveKey) {
        propsFile.inputStream().use { props.load(it) }

        val storeFileName = props.getProperty("storeFile") ?: ""
        val storePassword = props.getProperty("storePassword")
        val keyAlias      = props.getProperty("keyAlias")
        val keyPassword   = props.getProperty("keyPassword")

        if (
            storeFileName.isNotBlank() &&
            !storePassword.isNullOrBlank() &&
            !keyAlias.isNullOrBlank() &&
            !keyPassword.isNullOrBlank()
        ) {
            signingConfigs {
                create("release") {
                    // storeFile path is relative to the android/ folder
                    storeFile = rootProject.file(storeFileName)   // e.g. "upload-keystore.jks"
                    this.storePassword = storePassword
                    this.keyAlias = keyAlias
                    this.keyPassword = keyPassword
                }
            }
            println("✅ Release signing configured with ${rootProject.file(storeFileName).path}")
        } else {
            println("⚠️ key.properties missing fields; will fall back to DEBUG signing for release.")
        }
    } else {
        println("⚠️ key.properties not found; will use DEBUG signing for release.")
    }

    buildTypes {
        getByName("release") {
            // Use release signing if configured, else fall back to debug so you can still build
            val releaseConf = signingConfigs.findByName("release")
            signingConfig = releaseConf ?: signingConfigs.getByName("debug")

            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Firebase / Google services plugin
apply(plugin = "com.google.gms.google-services")

dependencies {
    implementation(kotlin("stdlib"))
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
