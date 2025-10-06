pipeline {
  agent any

  parameters {
    booleanParam(name: 'PUSH_IMAGE', defaultValue: false, description: 'Pousser l’image vers un registre ?')
    string(name: 'REGISTRY_URL', defaultValue: '', description: 'Ex: registry.example.com (laisser vide pour désactiver le push)')
    string(name: 'REGISTRY_CREDS_ID', defaultValue: 'REGISTRY_CREDS', description: 'Credentials ID (username/password) du registre')
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    disableConcurrentBuilds()
  }

  environment {
    IMAGE_NAME = 'node-redis-counter'
    IMAGE_TAG  = "${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'dev'}"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        script { currentBuild.displayName = "#${env.BUILD_NUMBER} ${env.IMAGE_TAG}" }
      }
    }

    stage('Unit Tests (Node in Docker)') {
      steps {
        sh '''
          docker run --rm -v "$PWD":/app -w /app node:20-alpine sh -lc "
            npm ci &&
            npm test
          "
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
          docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Integration Test (Docker Compose + Redis)') {
      steps {
        sh '''
          chmod +x tests/integration/test.sh
          ./tests/integration/test.sh
        '''
      }
    }

    stage('Push Image (optional)') {
      when {
        expression { return params.PUSH_IMAGE && params.REGISTRY_URL?.trim() }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: params.REGISTRY_CREDS_ID, usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            docker login -u "$REG_USER" -p "$REG_PASS" "${REGISTRY_URL}"

            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
            docker tag ${IMAGE_NAME}:latest     ${REGISTRY_URL}/${IMAGE_NAME}:latest

            docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest
          '''
        }
      }
    }
  }

  post {
    always {
      // Arrête/retire l’environnement d’intégration s’il est resté actif, puis nettoyage
      sh '''
        docker compose -f docker-compose.test.yml down -v || true
        docker system prune -af || true
      '''
      echo 'Pipeline terminé ✅'
    }
  }
}

