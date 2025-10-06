// Jenkinsfile (Scripted Pipeline)
node {
  // -------- Paramètres du job (optionnels) --------
  properties([
    parameters([
      booleanParam(name: 'PUSH_IMAGE', defaultValue: false, description: 'Pousser l image vers un registre ?'),
      stringParam(name: 'REGISTRY_URL', defaultValue: '', description: 'Ex: registry.example.com (laisser vide pour désactiver)'),
      stringParam(name: 'REGISTRY_CREDS_ID', defaultValue: 'REGISTRY_CREDS', description: 'Credentials ID (username/password) du registre')
    ])
  ])

  // -------- Variables pipeline --------
  def IMAGE_NAME = "node-redis-counter"
  def IMAGE_TAG  = ""
  currentBuild.displayName = "#${env.BUILD_NUMBER}"

  // Assure des logs horodatés
  wrap([$class: 'TimestamperBuildWrapper']) {
    try {
      stage('Checkout') {
        checkout scm
        // Tag court à partir du commit
        IMAGE_TAG = sh(returnStdout: true, script: "git rev-parse --short=7 HEAD").trim()
        echo "IMAGE_TAG=${IMAGE_TAG}"
      }

      stage('Unit Tests (Node inside Docker)') {
        sh '''
          docker run --rm -v "$PWD":/app -w /app node:20-alpine sh -lc "
            npm ci &&
            npm test
          "
        '''
      }

      stage('Build Docker Image') {
        sh """
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
          docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
        """
      }

      stage('Integration Test (Docker Compose + Redis)') {
        sh '''
          chmod +x tests/integration/test.sh
          ./tests/integration/test.sh
        '''
      }

      stage('Push Image (optional)') {
        // On push seulement si demandé et REGISTRY_URL non vide
        if (params.PUSH_IMAGE && params.REGISTRY_URL?.trim()) {
          withCredentials([usernamePassword(credentialsId: params.REGISTRY_CREDS_ID, usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
            sh """
              echo "Login to ${params.REGISTRY_URL} ..."
              docker login -u "$REG_USER" -p "$REG_PASS" "${params.REGISTRY_URL}"

              docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${params.REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
              docker tag ${IMAGE_NAME}:latest     ${params.REGISTRY_URL}/${IMAGE_NAME}:latest

              docker push ${params.REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
              docker push ${params.REGISTRY_URL}/${IMAGE_NAME}:latest
            """
          }
        } else {
          echo "Push image désactivé (PUSH_IMAGE=${params.PUSH_IMAGE}, REGISTRY_URL='${params.REGISTRY_URL}')"
        }
      }

      currentBuild.result = 'SUCCESS'
    } catch (err) {
      currentBuild.result = 'FAILURE'
      echo "Erreur: ${err}"
      throw err
    } finally {
      stage('Cleanup') {
        // Nettoyage best-effort
        sh '''
          docker compose -f docker-compose.test.yml down -v || true
          docker system prune -af || true
        '''
      }
    }
  }
}
