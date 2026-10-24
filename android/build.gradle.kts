allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Some plugins (e.g. file_picker) still pin an older compileSdk than newer
    // transitive AAR dependencies require. Force every Android subproject to
    // compile against SDK 36 so AAR metadata checks pass. Registered via
    // plugins.withId so it runs as the Android plugin is applied (before the
    // project is evaluated) and avoids importing AGP types into the root
    // build script.
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(android, 36)
            } catch (_: Exception) {
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
