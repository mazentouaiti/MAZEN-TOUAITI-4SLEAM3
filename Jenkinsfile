pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'touaitimazen472/student-management'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        APP_PORT = "8089"
        SONAR_HOST_URL = 'http://localhost:9000'
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

        stage('MVN SONARQUBE') {
            steps {
                script {
                    echo '🔍 Running SonarQube code analysis...'

                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            ./mvnw sonar:sonar \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_TOKEN} \
                            -Dsonar.projectKey=student-management-${BUILD_NUMBER} \
                            -Dsonar.skipTests=true
                        """
                    }
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
                retry(3) {
                    script {
                        echo '🐳 Building Docker image...'
                        sh """
                            docker build --no-cache \\
                                --build-arg MAVEN_OPTS="-Dmaven.wagon.http.retryHandler.count=5" \\
                                -t ${DOCKER_IMAGE}:${DOCKER_TAG} \\
                                -t ${DOCKER_IMAGE}:latest .

                            echo "✅ Docker image built successfully"
                            docker images | grep ${DOCKER_IMAGE} || echo "Image not found in list"
                        """
                    }
                }
            }
        }

        stage('Docker Login & Push') {
            steps {
                script {
                    echo '🔑 Logging into Docker Hub...'

                    // Logout first to clear any stale sessions
                    sh 'docker logout 2>/dev/null || true'

                    // Login with credentials
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh '''
                            echo "Logging in as $DOCKER_USERNAME..."
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                            # Verify login
                            if docker info | grep -q "Username: $DOCKER_USERNAME"; then
                                echo "✅ Docker login successful"
                            else
                                echo "❌ Docker login failed"
                                exit 1
                            fi
                        '''
                    }

                    echo "📤 Pushing Docker image..."

                    // Push with retry
                    retry(3) {
                        sh """
                            echo "Pushing ${DOCKER_IMAGE}:${DOCKER_TAG}..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}

                            echo "Pushing ${DOCKER_IMAGE}:latest..."
                            docker push ${DOCKER_IMAGE}:latest

                            echo "✅ Docker push completed!"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            sh '''
                echo "=== Cleanup started ==="
                docker logout 2>/dev/null || true
                echo "Cleanup completed!"
            '''
            cleanWs()
        }
        success {
            echo '✅ Pipeline succeeded!'
            echo "Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "Docker Image (latest): ${DOCKER_IMAGE}:latest"
            echo "Application URL when deployed: http://localhost:${APP_PORT}"
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                // Get the exact error
                sh '''
                    echo "=== Last 20 lines of Jenkins log ==="
                    tail -20 /var/log/jenkins/jenkins.log 2>/dev/null || echo "Cannot access Jenkins logs"

                    echo ""
                    echo "=== Docker Hub Connection Test ==="
                    timeout 10 curl -s -o /dev/null -w "%{http_code}" https://hub.docker.com || echo "Cannot connect"

                    echo ""
                    echo "=== Docker Disk Space ==="
                    docker system df 2>/dev/null || echo "Docker not available"

                    echo ""
                    echo "=== Current Docker Images ==="
                    docker images 2>/dev/null | head -15 || echo "Cannot list images"
                '''
            }
        }
    }
}