# node-redis-counter

App Express qui retourne:
- IP et hostname du conteneur
- IP du client
- Compteur global sauvegardé dans Redis (clé configurable)

## Variables d'env
- PORT (def: 3000)
- REDIS_URL (def: redis://localhost:6379)
- COUNTER_KEY (def: global:hits)
- SERVICE_NAME (def: node-redis-counter)

## Lancer local (dev ou CI)
# Besoin de Redis => voir test d'intégration (docker-compose.test.yml)

## Tests
- Unitaire: `npm ci && npm test`
- Intégration: `tests/integration/test.sh` (build image, démarre Redis + app via compose, vérifie l'incrément)

## Docker
- Build: `docker build -t node-redis-counter:dev .`
- Run: `docker run --rm -p 8080:3000 -e REDIS_URL=redis://host.docker.internal:6379 node-redis-counter:dev`
