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
// screen_protector skips applying the Kotlin plugin on AGP 9+, assuming
// AGP's built-in Kotlin compiles its sources — but gradle.properties has
// android.builtInKotlin=false (Flutter template default), so its .kt files
// were never compiled ("cannot find symbol ScreenProtectorPlugin"). Apply
// the Kotlin plugin to just that project instead of flipping the global
// flag, which would break plugins that still apply kotlin-android.
subprojects {
    if (name == "screen_protector") {
        plugins.withId("com.android.library") {
            apply(plugin = "org.jetbrains.kotlin.android")
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
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
