FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY . .

RUN chmod +x mvnw && \
    ./mvnw clean package -DskipTests

EXPOSE 8080

# Use the exact JAR filename
CMD ["java", "-jar", "target/student-management-0.0.1-SNAPSHOT.jar"]
