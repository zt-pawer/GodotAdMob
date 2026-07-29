plugins {
    id("com.android.library") version "8.7.3"
    id("org.jetbrains.kotlin.android") version "2.0.21"
}

android {
    namespace = "org.godotengine.plugin.godotadmob"
    compileSdk = 34
    ndkVersion = "28.0.12674087"

    defaultConfig {
        minSdk = 24
        targetSdk = 34

        ndk {
            abiFilters.add("arm64-v8a")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("CMakeLists.txt")
            version = "3.31.1"
        }
    }

    buildTypes {
        debug {
        }
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    compileOnly("org.godotengine:godot:4.7.1.stable")
}

// Copies build outputs into the demo's addon bin/ dir, matching the paths
// referenced by godot_ad_mob.gdextension and GodotAdMobExportPlugin.gd.
val demoAddonBinDir = layout.projectDirectory.dir("../demo/addons/GodotAdMob/bin/android")

listOf("debug", "release").forEach { variant ->
    val variantCapitalized = variant.replaceFirstChar { it.uppercase() }

    tasks.register<Copy>("copy${variantCapitalized}AARToDemoAddons") {
        dependsOn("assemble$variantCapitalized")
        from(layout.buildDirectory.file("outputs/aar/GodotAdMob-$variant.aar"))
        into(demoAddonBinDir.dir(variant))
    }

    tasks.register<Copy>("copy${variantCapitalized}SharedLibs") {
        dependsOn("merge${variantCapitalized}NativeLibs")
        from(layout.buildDirectory.dir("intermediates/merged_native_libs/$variant/merge${variantCapitalized}NativeLibs/out/lib/arm64-v8a")) {
            include("libGodotAdMob.so")
        }
        into(demoAddonBinDir.dir("$variant/arm64-v8a"))
    }
}

tasks.register("copyToDemoAddons") {
    dependsOn(
        "copyDebugAARToDemoAddons",
        "copyReleaseAARToDemoAddons",
        "copyDebugSharedLibs",
        "copyReleaseSharedLibs",
    )
}
