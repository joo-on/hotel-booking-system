plugins {
    alias(libs.plugins.spring.boot)
}

group = "dev.jooon"
version = "0.0.1-SNAPSHOT"
description = "property-service"

dependencies {
    implementation(platform(libs.spring.boot.bom))
    implementation(libs.spring.boot.web)
    implementation(libs.spring.boot.jpa)
    runtimeOnly(libs.mysql.connector)
    implementation(libs.spring.boot.security)

    testImplementation(libs.spring.boot.test)
}

tasks.withType<Test> {
    useJUnitPlatform()
}
