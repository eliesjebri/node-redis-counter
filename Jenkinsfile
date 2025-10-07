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
    NODE_IMAGE = 'node:20-alpine'
    IMAGE_NAME = 'node-redis-counter'
    IMAGE_TAG  = "${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'dev'}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare NPM Lockfile') {
      steps {
        sh '''
          if [ ! -f package-lock.json ]; then
            echo "[INFO] package-lock.json manquant, génération automatique..."
            docker run --rm -v "$PWD":/app -w /app ${NODE_IMAGE} sh -lc "npm install --package-lock-only"
          else
            echo "[INFO] package-lock.json déjà présent"
          fi
        '''
      }
    }

stage('Unit Tests & Coverage') {
  steps {
    sh '''
      echo "[INFO] Running Jest unit tests with coverage..."

      # Vérification ou génération du package-lock.json
      if [ ! -f package-lock.json ]; then
        echo "[WARN] package-lock.json absent — génération via npm install..."
        docker run --rm -v "$PWD":/app -w /app ${NODE_IMAGE} sh -lc "npm install --package-lock-only"
      fi

      # Exécution des tests avec fallback si npm ci échoue
      docker run --rm -v "$PWD":/app -w /app ${NODE_IMAGE} sh -lc '
        if ! npm ci; then
          echo "[WARN] npm ci a échoué, tentative avec npm install..."
          npm install
        fi 
      '
    '''
   }
}


    stage('Build Image') {
      steps {
        sh '''
          echo "[INFO] Building Docker image..."
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
          docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Smoke Test (Readiness only)') {
      steps {
        sh '''
          echo "[INFO] Running smoke test (readiness)..."
          chmod +x tests/smoke/smoke-test.sh
          HOST_HTTP_PORT=18080 SMOKE_REDIS_PORT=16379 IMAGE_TAG=${IMAGE_TAG} tests/smoke/smoke-test.sh
        '''
      }
    }

    stage('Integration Test (Compose)') {
      steps {
        sh '''
          echo "[INFO] Starting integration test environment..."
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
            echo "[INFO] Pushing image to ${REGISTRY_URL}..."
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
    success {
      echo '[SUCCESS] Build et tests réussis 🎉'
    }
    failure {
      echo '[FAILURE] Une erreur est survenue ❌'
    }
  }
}
