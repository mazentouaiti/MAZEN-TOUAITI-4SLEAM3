pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/mazentouaiti/MAZEN-TOUAITI-4SLEAM3.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Building the project...'
                // Add your build commands here
                // Example for Java: sh 'mvn clean compile'
                // Example for Node.js: sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                // Add your test commands here
                // Example: sh 'mvn test' or 'npm test'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying the project...'
                // Add deployment commands here
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}