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
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val adjustNamespace: () -> Unit = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val currentNamespace = getNamespace.invoke(android) as? String
                if (currentNamespace.isNullOrEmpty()) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val fallbackNamespace = "com.example." + project.name.replace(Regex("[^a-zA-Z0-9_]"), "_")
                    setNamespace.invoke(android, fallbackNamespace)
                }

                // Strip package attribute from AndroidManifest.xml to fix AGP 8+ error
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    var manifestContent = manifestFile.readText()
                    if (manifestContent.contains("package=")) {
                        manifestContent = manifestContent.replace(Regex("""package="[^"]*""""), "")
                        manifestFile.writeText(manifestContent)
                    }
                }
            } catch (e: Exception) {
                // Ignore if the methods are not found or failed
            }
        }
    }

    if (project.state.executed) {
        adjustNamespace()
    } else {
        project.afterEvaluate {
            adjustNamespace()
        }
    }
}



tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

