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
    HOST_HTTP_PORT = "${env.HOST_HTTP_PORT ?: '18080'}"
    SMOKE_REDIS_PORT = "${env.SMOKE_REDIS_PORT ?: '16379'}"
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
            npm ci && npm test
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

    stage('Smoke Test (readiness only)') {
      steps {
        sh '''
          set -eu
          echo "[SMOKE] Lancement Redis temporaire..."
          docker run -d --rm --name redis-smoke -p ${SMOKE_REDIS_PORT}:6379 redis:7-alpine

          echo "[SMOKE] Lancement de l’application..."
          docker run -d --rm --name nrc-smoke \
            --env-file .env.app \
            --add-host=host.docker.internal:host-gateway \
            -e REDIS_URL="redis://host.docker.internal:${SMOKE_REDIS_PORT}" \
            -p ${HOST_HTTP_PORT}:3000 \
            ${IMAGE_NAME}:${IMAGE_TAG}

          echo "[SMOKE] Attente de readiness (max 30s)..."
          for i in $(seq 1 30); do
            if curl -sf "http://localhost:${HOST_HTTP_PORT}/healthz" >/dev/null 2>&1; then
              echo "[SMOKE] ✅ Application prête"
              break
            fi
            sleep 1
            if [ "$i" -eq 30 ]; then
              echo "[SMOKE] ⛔ Timeout readiness"
              docker logs nrc-smoke || true
              exit 1
            fi
          done

          echo "[SMOKE] Arrêt des conteneurs..."
          docker stop nrc-smoke || true
          docker stop redis-smoke || true
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
      sh '''
        docker stop nrc-smoke redis-smoke 2>/dev/null || true
        docker compose -f docker-compose.test.yml down -v || true
        docker system prune -af || true
      '''
      echo 'Pipeline terminé ✅'
    }
  }
}
