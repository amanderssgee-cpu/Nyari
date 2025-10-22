import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---- Load MAPS_API_KEY from (priority): Gradle prop -> ENV -> local.properties
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val MAPS_API_KEY: String =
    (project.findProperty("MAPS_API_KEY") as String?)
        ?: System.getenv("MAPS_API_KEY")
        ?: localProps.getProperty("MAPS_API_KEY", "")

android {
    namespace = "com.nyari.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Java 17 / Kotlin 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    defaultConfig {
        applicationId = "com.nyari.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Inject Google Maps key into manifest (used by <meta-data> tags)
        manifestPlaceholders["MAPS_API_KEY"] = MAPS_API_KEY
    }

    // ---- Signing (release if key.properties present; else fallback to debug) ----
    val props = Properties()
    val propsFile = rootProject.file("key.properties")
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
                    storeFile = rootProject.file(storeFileName) // e.g. upload-keystore.jks
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
            val releaseConf = signingConfigs.findByName("release")
            signingConfig = releaseConf ?: signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter { source = "../.." }

// Firebase / Google services plugin
apply(plugin = "com.google.gms.google-services")

dependencies {
    implementation(kotlin("stdlib"))
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
