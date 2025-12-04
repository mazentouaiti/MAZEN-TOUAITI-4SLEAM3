FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY . .
# Use a more reliable Maven mirror
ENV MAVEN_MIRROR_URL=https://repo1.maven.org/maven2

# Clear any corrupted downloads and retry with backoff
RUN chmod +x mvnw && \
    rm -rf ~/.m2/repository/org/hibernate && \
    (./mvnw clean package -DskipTests || \
     sleep 10 && ./mvnw clean package -DskipTests || \
     sleep 15 && ./mvnw clean package -DskipTests -o)

EXPOSE 8089

# Default command uses docker profile (with MySQL)
# But can be overridden with SPRING_PROFILES_ACTIVE environment variable
ENTRYPOINT ["sh", "-c", "java -jar target/student-management-*.jar"]
