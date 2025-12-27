plugins {
    java
    alias(libs.plugins.lombok) apply false
    alias(libs.plugins.spring.boot) apply false
}

subprojects {
    apply(plugin = "java")
    apply(plugin = "io.freefair.lombok")

    java {
        toolchain {
            languageVersion = JavaLanguageVersion.of(25)
        }
    }

    // Load .env into bootRun only when explicitly requested via -Pdotenv.
    if (project.hasProperty("dotenv")) {
        val envFile = rootProject.file(".env")
        if (envFile.isFile) {
            val envVars = envFile.readLines()
                .map { it.trim() }
                .filter { it.isNotEmpty() && !it.startsWith("#") }
                .mapNotNull { line ->
                    val sanitized = line.removePrefix("export ").trim()
                    val index = sanitized.indexOf('=')
                    if (index <= 0) {
                        null
                    } else {
                        sanitized.substring(0, index) to sanitized.substring(index + 1)
                    }
                }
                .toMap()

            tasks.withType<org.springframework.boot.gradle.tasks.run.BootRun>().configureEach {
                environment(envVars)
            }
        }
    }
}
