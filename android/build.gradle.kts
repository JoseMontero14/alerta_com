import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// Configuración de los repositorios globales
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Definir una nueva ruta para los directorios de compilación
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Configuración para subproyectos
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Limpiar compilaciones previas
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Dependencias de compilación
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Plugin de servicios de Google
        classpath("com.android.tools.build:gradle:8.0.2")
        classpath("com.google.gms:google-services:4.4.2")
    }
}
