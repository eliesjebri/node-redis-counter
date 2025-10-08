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

stage('Unit Tests & Coverage') {
  steps {
    sh '''
      echo "[INFO] Running Jest unit tests with coverage..."
      docker run --rm -v "$PWD":/app -w /app node:20-alpine sh -lc "
        npm ci &&
        npm run test:coverage
      "
    '''
    
    junit allowEmptyResults: true, testResults: '**/junit.xml'
    
    recordCoverage(
      tools: [[parser: 'COBERTURA', pattern: 'coverage/cobertura-coverage.xml']],
      sourceCodeRetention: 'EVERY_BUILD',
      qualityGates: [[threshold: 70.0, metric: 'LINE']]
)
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
