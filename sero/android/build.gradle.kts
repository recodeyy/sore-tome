plugins {
    // Add the Google services Gradle plugin (applied at app level)
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


// Redirect build outputs to the project-root `build/` dir so the Flutter tool
// can locate the produced APK/AAB (otherwise it looks in build/app/outputs while
// Gradle writes to android/app/build/outputs and reports "couldn't find .apk").
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
