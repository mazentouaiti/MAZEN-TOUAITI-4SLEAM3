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
                    writeFile file: 'src/test/resources/application-test.properties', text: '''# Test profile with H2 in-memory database
spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=false
spring.h2.console.enabled=false'''

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
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest .
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }

        stage('Test Docker Container - Solo') {
            steps {
                script {
                    echo "Testing Docker container without database..."
                    sh """
                        # Clean up old container
                        docker stop test-container 2>/dev/null || true
                        docker rm -f test-container 2>/dev/null || true

                        # Run the FRESHLY BUILT image
                        docker run -d --name test-container -p 8090:8089 \\
                            ${DOCKER_IMAGE}:${DOCKER_TAG}

                        # Wait for startup
                        sleep 15

                        # Check container status
                        if docker ps | grep -q test-container; then
                            echo "✅ Container is running"
                            echo "=== Container logs (last 20 lines) ==="
                            docker logs test-container --tail 20
                        else
                            echo "❌ Container failed to start"
                            docker logs test-container
                            exit 1
                        fi

                        # Clean up
                        docker stop test-container
                        docker rm test-container
                    """
                }
            }
        }

        stage('Test with Docker Compose - Full Stack') {
            steps {
                script {
                    echo 'Testing with Docker Compose (MySQL + App)...'
                    sh '''
                        # Stop any running containers
                        docker compose down || true

                        # Build and start fresh
                        docker compose up -d --build

                        # Wait longer for MySQL to initialize
                        echo "Waiting for services to start..."
                        sleep 60

                        echo "=== Checking MySQL health ==="
                        docker compose exec mysql-db mysqladmin ping -h localhost -u root -proot123 || echo "MySQL health check failed"

                        echo "=== Application logs ==="
                        docker compose logs student-app --tail=30

                        echo "=== Testing health endpoint ==="
                        # Try multiple times with delays
                        for i in {1..5}; do
                            echo "Attempt $i/5..."
                            if curl -s -f http://localhost:8081/actuator/health; then
                                echo "✅ Health check passed!"
                                break
                            else
                                echo "Health check failed, waiting 10 seconds..."
                                sleep 10
                            fi
                        done

                        echo "=== Testing application endpoint ==="
                        curl -s http://localhost:8081/ || echo "Application endpoint not available"

                        # Stop services
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
                docker compose down 2>/dev/null || true
                docker rm -f test-container 2>/dev/null || true
                docker system prune -f 2>/dev/null || true
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
            sh '''
                echo "=== Debug information ==="
                docker ps -a | head -10
                docker compose logs --tail=50 2>/dev/null || echo "No compose logs"
            '''
        }
    }
}