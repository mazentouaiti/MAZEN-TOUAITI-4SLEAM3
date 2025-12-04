FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY . .

RUN chmod +x mvnw && \
    ./mvnw clean package -DskipTests

EXPOSE 8089

# Default command uses docker profile (with MySQL)
# But can be overridden with SPRING_PROFILES_ACTIVE environment variable
ENTRYPOINT ["sh", "-c", "java -jar target/student-management-*.jar"]
