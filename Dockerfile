# FROM eclipse-temurin:21-jre

# WORKDIR /app
# COPY target/quarkus-app/ /app/

# EXPOSE 8080
# USER 1001
# ENTRYPOINT ["java", "-Dquarkus.http.host=0.0.0.0", "-jar", "quarkus-run.jar"]

# ---- Build: compila o app dentro do Render (testes ja rodaram no CI) ----
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN chmod +x mvnw && ./mvnw -B -q dependency:go-offline
COPY src src
RUN ./mvnw -B package -DskipTests

# ---- Runtime ----
FROM eclipse-temurin:25-jre
WORKDIR /deployments
RUN useradd --system --uid 1001 quarkus
COPY --from=build --chown=1001 /app/target/quarkus-app/lib/ ./lib/
COPY --from=build --chown=1001 /app/target/quarkus-app/*.jar ./
COPY --from=build --chown=1001 /app/target/quarkus-app/app/ ./app/
COPY --from=build --chown=1001 /app/target/quarkus-app/quarkus/ ./quarkus/
USER 1001

# Render injeta PORT; MaxRAMPercentage respeita o limite de memoria da instancia.
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -Dquarkus.http.host=0.0.0.0"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar quarkus-run.jar"]
