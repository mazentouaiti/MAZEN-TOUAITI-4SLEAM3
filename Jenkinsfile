pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'touaitimazen472/student-management'
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
                retry(3) {
                    script {
                        sh '''
                            docker build --no-cache \
                                --build-arg MAVEN_OPTS="-Dmaven.wagon.http.retryHandler.count=5" \
                                -t student-management:latest .
                        '''
                    }
                }
            }
        }
        stage('Docker push') {
            steps {
                script {
                    echo "Pushing Docker image to ${DOCKER_REGISTRY}..."
                    sh '''
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }
        stage('Verify Image on Registry') {
            steps {
                script {
                    echo "Verifying Docker image on ${DOCKER_REGISTRY}..."
                    sh '''
                          docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}

                          docker run --rm \
                                  ${DOCKER_IMAGE}:${DOCKER_TAG} \
                                  sh -c "echo 'Image verified successfully'"

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