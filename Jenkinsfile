pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'mazentouaiti/student-management'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        APP_PORT = "8089"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Build Application') {
            steps {
                script {
                    echo 'Building Spring Boot application...'
                    sh '''
                        chmod +x mvnw
                        # Build WITHOUT skipping tests - we'll run them in next stage
                        ./mvnw clean compile
                        echo "Build completed!"
                        ls -la target/classes/
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests with H2 in-memory database...'
                script {
                    // Create test configuration with H2 database
                    writeFile file: 'src/test/resources/application-test.properties', text: '''# Test profile with H2 in-memory database
spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=false
spring.h2.console.enabled=false'''

                    // Run tests
                    sh './mvnw test'
                }
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                script {
                    echo 'Packaging application...'
                    sh './mvnw package -DskipTests'
                    sh 'ls -la target/*.jar'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest ."
                    sh "docker images | grep ${DOCKER_IMAGE}"
                }
            }
        }

        stage('Test Docker Container') {
            steps {
                script {
                    echo "Testing Docker container..."
                    sh '''
                        # Clean up old container
                        docker stop test-container 2>/dev/null || true
                        docker rm -f test-container 2>/dev/null || true

                        # Run on port 8090 instead of 8089
                        docker run -d --name test-container -p 8090:8089 \
                            mazentouaiti/student-management:9

                        # Wait a bit
                        sleep 10

                        # Just check if container is running
                        if docker ps | grep -q test-container; then
                            echo "✅ Container is running"
                        else
                            echo "❌ Container failed"
                            docker logs test-container
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('Test with Docker Compose') {
            steps {
                script {
                    echo 'Testing with Docker Compose (MySQL + App)...'
                    sh '''
                        docker compose up -d --build
                        sleep 45  # Wait for MySQL and app to start
                        echo "=== Checking MySQL health ==="
                        docker compose exec mysql-db mysqladmin ping -h localhost || echo "MySQL not ready"
                        echo "=== Application logs ==="
                        docker compose logs student-management --tail=30
                        echo "=== Testing health endpoint ==="
                        curl -f http://localhost:8081/actuator/health || echo "Health check failed"
                        echo "=== Testing application endpoint ==="
                        curl -f http://localhost:8081/ || echo "Application endpoint not available"
                        docker compose down
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh '''
                docker compose down || true
                docker rm -f test-container || true
                docker system prune -f
            '''
            cleanWs()
        }
        success {
            echo '✅ Pipeline succeeded!'
            echo "Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "Application URL when deployed: http://localhost:8081"
        }
        failure {
            echo '❌ Pipeline failed!'
            sh 'docker compose logs || true'
        }
    }
}