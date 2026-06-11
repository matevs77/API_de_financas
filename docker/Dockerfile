# Stage 1: build
FROM eclipse-temurin:17-jdk-alpine AS build
RUN apk add --no-cache maven
WORKDIR /app

COPY pom.xml ./
COPY src ./src

# If mvnw exists, prefer it; otherwise use Maven directly.
RUN if [ -f mvnw ]; then ./mvnw -q -DskipTests package; else mvn -q -DskipTests package; fi

# Stage 2: runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

