# 🧩 Node Redis Counter — CI/CD Pipeline avec Jenkins

## 📘 Description

**Node Redis Counter** est une application Node.js (ESM, `import/export`) qui :
- affiche le **nom d’hôte**, l’**adresse IP** de la machine d’exécution et la **version du service**,  
- maintient un **compteur global persistant** dans **Redis**.

Elle est conçue pour être **déployée dans un conteneur Docker**, testée et buildée via **Jenkins Pipeline**,  
et **scalée horizontalement** grâce à un stockage Redis partagé.

---

## ⚙️ Fonctionnalités principales

| Fonction | Description |
|-----------|--------------|
| 🌐 **Affichage dynamique** | Nom d’hôte, IP, version, compteur Redis |
| 🧰 **Configuration flexible** | Ports et variables injectés depuis `.env.app` |
| 🧪 **Tests unitaires** | Jest (ESM compatible, Node 20) |
| 📊 **Rapport de couverture** | Généré par Jest et publié dans Jenkins |
| 🧱 **Pipeline Docker CI/CD complet** | Build, test, smoke test, intégration, push optionnel |
| 🔒 **Redis externalisé** | Permet la réplication et le scaling |
| 🐳 **100 % Docker-native** | Aucun environnement Node local requis |

---

## 🗂️ Structure du projet

```
node-redis-counter/
├── src/
│   ├── server.js
│   └── utils.js
├── tests/
│   ├── unit/utils.test.js
│   ├── smoke/smoke-test.sh
│   └── integration/test.sh
├── .env.app
├── Dockerfile
├── docker-compose.test.yml
├── jest.config.js
├── package.json
├── package-lock.json
├── Jenkinsfile
└── README.md
```

---

## 🧰 Variables et fichiers d’environnement

### `.env.app`
Fichier chargé au **runtime** par Docker Compose et les scripts de test :

```bash
APP_PORT=3000
REDIS_HOST=redis
REDIS_PORT=6379
SERVICE_VERSION=1.0.0
```

💡 Ce fichier **n’est pas versionné** (protégé via `.gitignore`),  
mais un modèle peut être fourni via `.env.app.example`.

---

## 🧪 Tests unitaires et couverture (Jest)

### Scripts npm
```bash
npm test              # Exécute Jest (ESM)
npm run test:debug    # Mode verbose pour debug CI
npm run test:coverage # Jest avec rapport LCOV
```

### Configuration Jest (`jest.config.js`)
```js
export default {
  testEnvironment: "node",
  transform: {},
  roots: ["<rootDir>/tests/unit"],
  moduleNameMapper: { "^(\.{1,2}/.*)\.js$": "$1" }
};
```

### Rapport de couverture
Les rapports sont générés dans :
```
coverage/
├── lcov.info
└── lcov-report/index.html
```

---

## 🧱 Docker et Build

### Dockerfile
```Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Docker Compose (tests)
```yaml
services:
  app:
    build: .
    env_file: .env.app
    ports:
      - "${APP_PORT}:3000"
    depends_on:
      - redis
  redis:
    image: redis:7-alpine
```

---

## ⚙️ Jenkins CI/CD Pipeline

### 🔹 Fichier : `Jenkinsfile`

Le pipeline comprend les étapes suivantes :

| Stage | Description |
|--------|--------------|
| **Checkout** | Récupère le code source depuis Git |
| **Prepare NPM Lockfile** | Crée `package-lock.json` si absent |
| **Unit Tests & Coverage** | Exécute Jest, génère les rapports JUnit + LCOV |
| **Build Image** | Construit et tague l’image Docker (`latest` + commit) |
| **Smoke Test (readiness)** | Vérifie le démarrage rapide de l’app |
| **Integration Test (Compose)** | Lance un environnement complet avec Redis |
| **Push Image (optional)** | Pousse l’image vers un registre Docker |

---

### 🔹 Plugins Jenkins nécessaires

| Plugin | Rôle |
|---------|------|
| 🧩 **Docker Pipeline** | Permet l’exécution de commandes Docker (`build`, `run`, `compose`) |
| 🧩 **JUnit** | Affiche les résultats de tests Jest |
| 📊 **Coverage** (`publishCoverage`) | Affiche les rapports de couverture Jest |
| 🔐 **Credentials Binding** | Gère l’authentification au registre Docker |
| ⚙️ **Git Plugin** | Intègre le code source Git |
| 🕒 **Timestamper** | Ajoute des timestamps aux logs |
| 🧹 **Build Discarder** | Nettoie les anciens builds |

---

### 🔹 Paramètres du pipeline

| Nom | Type | Description |
|------|------|-------------|
| `PUSH_IMAGE` | booléen | Si vrai → pousse l’image vers le registre |
| `REGISTRY_URL` | string | URL du registre Docker |
| `REGISTRY_CREDS_ID` | string | ID des credentials Jenkins (`username/password`) |

---

### 🔹 Variables d’environnement utilisées

| Variable | Description |
|-----------|-------------|
| `NODE_IMAGE` | Image Node utilisée pour les tests (`node:20-alpine`) |
| `IMAGE_NAME` | Nom de l’image Docker (`node-redis-counter`) |
| `IMAGE_TAG` | Tag de build (`GIT_COMMIT[0..6]` ou `dev`) |
| `APP_ENV` | Fichier `.env.app` utilisé au runtime |

---

### 🔹 Résultats Jenkins visibles

- 📄 **Test Results** → Résultats Jest (via JUnit)  
- 📊 **Coverage Report** → Pourcentage de couverture LCOV  
- 🧱 **Console Output** → Logs npm + Docker + Redis  
- 📦 *(optionnel)* **Artifacts** → Rapports HTML (`coverage/lcov-report`)

---

## 🚀 Exécution locale

Pour tester sans Jenkins :

```bash
# Build l’image
docker build -t node-redis-counter .

# Démarre l’environnement de test
docker compose -f docker-compose.test.yml up -d

# Vérifie l’application
curl http://localhost:3000
```

---

## 🧹 Nettoyage

```bash
docker compose -f docker-compose.test.yml down -v
docker system prune -af
```

---

## 🧠 Points clés

- Projet **100 % ESM** (Node ≥ 20)
- Jest exécuté via `--experimental-vm-modules`
- Pipeline **full Docker**, aucun Node local nécessaire
- Jenkins publie **JUnit + Coverage**
- Image Docker **optionnellement poussée** vers un registre privé

---

## 📎 Exemple de build réussi

```
[INFO] Running Jest unit tests with coverage...
PASS tests/unit/utils.test.js
  getHostInfo
    ✓ retourne hostname et ip (5 ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
--------------------|---------|----------|---------|---------|-------------------
File                | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
--------------------|---------|----------|---------|---------|-------------------
All files           |   95.45 |    90.00 |   100.0 |   95.45 |
src/utils.js        |   100.0 |      100 |     100 |   100.0 |
--------------------|---------|----------|---------|---------|-------------------
[SUCCESS] Build et tests réussis 🎉
```
