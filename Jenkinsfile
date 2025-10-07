pipeline {
  agent any

  parameters {
    booleanParam(name: 'PUSH_IMAGE', defaultValue: false, description: 'Pousser l’image vers un registre ?')
    string(name: 'REGISTRY_URL', defaultValue: '', description: 'Ex: registry.example.com')
    string(name: 'REGISTRY_CREDS_ID', defaultValue: 'REGISTRY_CREDS', description: 'Credentials ID du registre')
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
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          docker run --rm -v "$PWD":/app -w /app node:20-alpine sh -lc "
            npm ci && npm test
          "
        '''
      }
    }

    stage('Build Image') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
          docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Smoke Test (readiness only)') {
      steps {
        sh '''
          chmod +x tests/smoke/smoke-test.sh
          HOST_HTTP_PORT=18080 SMOKE_REDIS_PORT=16379 IMAGE_TAG=${IMAGE_TAG} tests/smoke/smoke-test.sh
        '''
      }
    }

    stage('Integration Test (Compose)') {
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
            docker tag ${IMAGE_NAME}:latest ${REGISTRY_URL}/${IMAGE_NAME}:latest
            docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest
          '''
        }
      }
    }
  }

  post {
    always {
      sh '''
        docker stop nrc-smoke redis-smoke 2>/dev/null || true
        docker compose -f docker-compose.test.yml down -v || true
        docker system prune -af || true
      '''
      echo 'Pipeline terminé ✅'
    }
  }
}
