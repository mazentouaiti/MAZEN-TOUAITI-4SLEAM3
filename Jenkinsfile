pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'docker.io'  // Change to your registry (Docker Hub, ECR, etc.)
        DOCKER_IMAGE = 'mazentouaiti/student-management'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Application') {
            steps {
                script {
                    echo 'Building the application...'
                    // Your existing build commands
                    // sh 'mvn clean package' or 'npm run build'
                }
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                // Your test commands
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }

        stage('Run Docker Container Tests') {
            steps {
                script {
                    echo 'Testing Docker container...'
                    sh "docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} echo 'Container works!'"
                    // Or run actual tests in container
                    // sh "docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} npm test"
                }
            }
        }

        stage('Push Docker Image') {
            when {
                branch 'main'  // Only push on main branch
            }
            steps {
                script {
                    echo 'Pushing Docker image to registry...'
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh "echo ${DOCKER_PASS} | docker login ${DOCKER_REGISTRY} -u ${DOCKER_USER} --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
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
                    echo 'Deploying Docker container...'
                    // Example: Deploy to a server
                    sh """
                        docker stop student-management-container || true
                        docker rm student-management-container || true
                        docker run -d \
                          --name student-management-container \
                          -p 8080:8080 \
                          ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
    }
    stage('Docker Compose Test') {
        steps {
            script {
                echo 'Testing with docker-compose...'
                sh 'docker-compose up -d'
                sleep(time: 10, unit: 'SECONDS') // Wait for services to start
                sh 'docker-compose exec app npm test || true' // Run tests
                sh 'docker-compose down'
            }
        }
    }
    post {
        always {
            // Clean up Docker
            sh 'docker system prune -f'
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded! Docker image built and deployed.'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}