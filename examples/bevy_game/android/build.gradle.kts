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

        ndk {
            abiFilters.addAll(listOf("arm64-v8a"/*, "armeabi-v7a", "x86", "x86_64"*/))
        }
    }

    lint {
        abortOnError = false
        disable.addAll(listOf("MissingTranslation", "UnusedResources"))
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
        }
    }
    sourceSets {
        getByName("main") {
            manifest.srcFile("AndroidManifest.xml")
            java.srcDirs("src")
            assets.srcDirs("../assets")
            res.srcDirs("res_android")
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }
}

dependencies {
    // implementation(libs.kotlin.stdlib)
    implementation(libs.androidx.appcompat)
    implementation(libs.games.activity)
}

cargo {
    module = ".."
    libname = "bevy_game"
    targets = listOf("arm64"/*, "arm", "x86", "x86_64"*/)
    targetDirectory = "../target"
    profile = if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
        "release"
    } else {
        "debug"
    }
}

val architectureMap = mapOf(
    "armeabi-v7a" to mapOf(
        "rustTarget" to "armv7-linux-androideabi",
        "ndkTarget" to "arm-linux-androideabi"
    ),
    "arm64-v8a" to mapOf(
        "rustTarget" to "aarch64-linux-android",
        "ndkTarget" to "aarch64-linux-android"
    ),
    "x86" to mapOf(
        "rustTarget" to "i686-linux-android",
        "ndkTarget" to "i686-linux-android"
    ),
    "x86_64" to mapOf(
        "rustTarget" to "x86_64-linux-android",
        "ndkTarget" to "x86_64-linux-android"
    )
)

tasks.register("copyNativeLibs") {
    val ndkDir = android.ndkDirectory
    val cppLibBasePath = "$ndkDir/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib"
    val jniLibsDir = file("src/main/jniLibs")
    
    doFirst {
        jniLibsDir.mkdirs()
    }
    
    doLast {
        architectureMap.forEach { (androidAbi, targets) ->
            val ndkTarget = targets["ndkTarget"]
            val sourceFile = file("$cppLibBasePath/$ndkTarget/libc++_shared.so")
            val destDir = file("$jniLibsDir/$androidAbi")
            val destFile = file("$destDir/libc++_shared.so")
            
            if (sourceFile.exists()) {
                destDir.mkdirs()
                sourceFile.copyTo(destFile, overwrite = true)
                println("  ✓ Copy libc++_shared.so to $androidAbi")
            } else {
                logger.warn("  ⚠ libc++_shared.so not found in: ${sourceFile.absolutePath}")
            }
        }
        println("✅ Success copy native libraries")
    }
}

tasks.whenTaskAdded {
    if (name == "mergeDebugJniLibFolders" || name == "mergeReleaseJniLibFolders") {
        dependsOn("cargoBuild", "copyNativeLibs")
    }
}

tasks.register<Delete>("cleanNativeLibs") {
    delete("src/main/jniLibs")
}

tasks.named("clean") {
    dependsOn("cleanNativeLibs")
}

fun getExportPackageName(): String {
    return if (project.hasProperty("export_package_name")) {
        project.property("export_package_name").toString()
    } else {
        "com.sergioriebra.bevy_game"
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
