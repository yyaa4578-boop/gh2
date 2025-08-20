// Top-level build file where you can add configuration options common to all sub-projects/modules.

plugins {
    // Example: id("com.android.application") version "8.5.0" apply false
    // id("org.jetbrains.kotlin.android") version "1.9.23" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// إصلاح مكان build directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// إصلاح هذا السطر
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
