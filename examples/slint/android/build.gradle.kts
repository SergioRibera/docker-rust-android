// import org.mozilla.rust.android.gradle.tasks.CargoBuildTask

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.rust.android)
}

android {
    namespace = getExportPackageName()
    compileSdk = libs.versions.compile.sdk.get().toInt()
    buildToolsVersion = libs.versions.build.tools.get()
    ndkVersion = libs.versions.ndk.get()

    compileOptions {
        sourceCompatibility = JavaVersion.toVersion(libs.versions.java.get())
        targetCompatibility = JavaVersion.toVersion(libs.versions.java.get())
    }

    kotlinOptions {
        jvmTarget = libs.versions.java.get()
    }

    defaultConfig {
        aaptOptions {
            ignoreAssetsPattern = "!.svn:!.git:!.gitignore:!.ds_store:!*.scc:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"
        }

        applicationId = getExportPackageName()
        versionCode = getExportVersionCode()
        versionName = getExportVersionName()
        minSdk = getExportMinSdkVersion()
        targetSdk = getExportTargetSdkVersion()

        missingDimensionStrategy("products", "template")
    }

    lint {
        abortOnError = false
        disable.addAll(listOf("MissingTranslation", "UnusedResources"))
    }

    sourceSets {
        getByName("main") {
            manifest.srcFile("AndroidManifest.xml")
            java.srcDirs("src")
            assets.srcDirs("../../assets")
            res.srcDirs("../../res_android")
        }
    }
}

dependencies {
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.constraintlayout)
}

cargo {
    module = "../"
    libname = "slint_test"
    targets = listOf("arm64")
    targetDirectory = "../target"
    profile = if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
        "release"
    } else {
        "debug"
    }
}

tasks.whenTaskAdded {
    if (name == "mergeDebugJniLibFolders" || name == "mergeReleaseJniLibFolders") {
        dependsOn("cargoBuild")
    }
}

// Funciones de configuración (pueden moverse a un script aparte si prefieres)
fun getExportPackageName(): String {
    return if (project.hasProperty("export_package_name")) {
        project.property("export_package_name").toString()
    } else {
        "com.sergioriebra.slint_test"
    }
}

fun getExportVersionCode(): Int {
    val versionCodeStr = if (project.hasProperty("export_version_code")) {
        project.property("export_version_code").toString()
    } else {
        "1"
    }
    return versionCodeStr.toIntOrNull() ?: 1
}

fun getExportVersionName(): String {
    return if (project.hasProperty("export_version_name")) {
        project.property("export_version_name").toString()
    } else {
        "1.0"
    }
}

fun getExportMinSdkVersion(): Int {
    val minSdkVersionStr = if (project.hasProperty("export_version_min_sdk")) {
        project.property("export_version_min_sdk").toString()
    } else {
        libs.versions.min.sdk.get()
    }
    return minSdkVersionStr.toIntOrNull() ?: libs.versions.min.sdk.get().toInt()
}

fun getExportTargetSdkVersion(): Int {
    val targetSdkVersionStr = if (project.hasProperty("export_version_target_sdk")) {
        project.property("export_version_target_sdk").toString()
    } else {
        libs.versions.target.sdk.get()
    }
    return targetSdkVersionStr.toIntOrNull() ?: libs.versions.target.sdk.get().toInt()
}
