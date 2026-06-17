FROM maven:3.9-eclipse-temurin-17 AS build
ARG APP_DIR=app/was_blue
WORKDIR /app
COPY ${APP_DIR}/pom.xml .
RUN mvn dependency:go-offline
COPY ${APP_DIR}/src ./src
RUN mvn -DskipTests package

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/kbeauty-app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
