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
                        ./mvnw clean package -DskipTests
                        echo "Build completed!"
                        ls -la target/*.jar
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh './mvnw test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
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
                    echo 'Testing Docker container without DB...'
                    sh """
                        docker run -d --name test-container \
                          -p ${APP_PORT}:${APP_PORT} \
                          -e SPRING_PROFILES_ACTIVE=test \
                          ${DOCKER_IMAGE}:${DOCKER_TAG}
                        sleep 15
                        docker logs test-container | tail -20
                        docker stop test-container || true
                        docker rm test-container || true
                    """
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

        stage('Push Docker Image') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Pushing Docker image to registry...'
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
                            docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_USER}/${DOCKER_IMAGE}:latest
                            docker push ${DOCKER_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_USER}/${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Deploying with Docker Compose...'
                    sh '''
                        docker compose down || true
                        docker compose up -d --build
                        echo "Deployment completed!"
                        echo "Application URL: http://localhost:8081"
                        echo "MySQL Port: 3306"
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
            script {
                if (env.BRANCH_NAME == 'main') {
                    echo 'Production deployment completed!'
                    echo "Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    echo "Application URL: http://localhost:8081"
                }
            }
        }
        failure {
            echo '❌ Pipeline failed!'
            sh 'docker compose logs || true'
        }
    }
}