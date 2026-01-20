// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mirpuertas.mediary"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mirpuertas.mediary"

        // Valores base de Flutter
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // Toman de pubspec.yaml (versionName y versionCode)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Firma release: se configura con `android/key.properties` (NO commitear) o por variables de entorno.
    // Ejemplo de variables de entorno:
    // - KEYSTORE_FILE (ruta al .jks, absoluta o relativa a android/)
    // - KEYSTORE_PASSWORD
    // - KEY_ALIAS
    // - KEY_PASSWORD
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()

    fun env(name: String): String? =
        System.getenv(name)?.takeIf { it.isNotBlank() }

    val hasKeystoreFile = keystorePropertiesFile.exists()
    if (hasKeystoreFile) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    } else {
        env("KEYSTORE_FILE")?.let { keystoreProperties["storeFile"] = it }
        env("KEYSTORE_PASSWORD")?.let { keystoreProperties["storePassword"] = it }
        env("KEY_ALIAS")?.let { keystoreProperties["keyAlias"] = it }
        env("KEY_PASSWORD")?.let { keystoreProperties["keyPassword"] = it }
    }

    fun prop(name: String): String? =
        (keystoreProperties[name] as? String)?.takeIf { it.isNotBlank() }

    val signingReady =
        prop("storeFile") != null &&
            prop("storePassword") != null &&
            prop("keyAlias") != null &&
            prop("keyPassword") != null

    signingConfigs {
        create("release") {
            if (signingReady) {
                keyAlias = prop("keyAlias")
                keyPassword = prop("keyPassword")

                val storeFilePath = prop("storeFile")!!
                // Acepta rutas absolutas, relativas a `android/` o relativas a `android/app/`.
                val resolvedStoreFile =
                    rootProject.file(storeFilePath).takeIf { it.exists() } ?: file(storeFilePath)
                storeFile = resolvedStoreFile
                storePassword = prop("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Para empezar, dejalo sin minify/shrink para evitar dolores
            isMinifyEnabled = false
            isShrinkResources = false

            if (!signingReady) {
                throw GradleException(
                    """
                    Release signing is not configured.

                    Create `android/key.properties` (see `android/key.properties.example`) or set env vars:
                      - KEYSTORE_FILE
                      - KEYSTORE_PASSWORD
                      - KEY_ALIAS
                      - KEY_PASSWORD
                    """.trimIndent()
                )
            }

            signingConfig = signingConfigs.getByName("release")
        }

        getByName("debug") {
            // No hace falta tocar nada; queda firma debug por defecto
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
