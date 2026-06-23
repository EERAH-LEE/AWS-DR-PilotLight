FROM maven:3.9-eclipse-temurin-17 AS build
ARG APP_DIR=app/was_blue
WORKDIR /app
COPY ${APP_DIR}/pom.xml .
RUN mvn dependency:go-offline
COPY ${APP_DIR}/src ./src
RUN mvn -DskipTests package

FROM eclipse-temurin:17-jre-alpine
ARG WHATAP_DIR=whatap
WORKDIR /app
COPY ${WHATAP_DIR} /whatap
COPY ${WHATAP_DIR}/was/whatap.conf /whatap/whatap.conf
COPY --from=build /app/target/kbeauty-app.jar app.jar
ENV WHATAP_AGENT_PATH=/whatap/whatap.agent-2.2.75.jar
ENV WHATAP_ONAME=aws-monitoring-blue
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java -javaagent:${WHATAP_AGENT_PATH} -Dwhatap.oname=${WHATAP_ONAME} -jar app.jar"]