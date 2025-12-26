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
}
