allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Put each subproject’s build/ under the shared ../../build folder
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure :app evaluates first (skip self to avoid cycles)
    if (project.path != ":app") {
        project.evaluationDependsOn(":app")
    }

    // --- Global compiler settings (safe for AGP) ---
    // Java: target Java 17 and silence the 'obsolete options' warning
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
        // IMPORTANT: do NOT set options.release with Android Gradle Plugin
        options.compilerArgs.add("-Xlint:-options")
    }

    // Kotlin: target JVM 17
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
