#!/usr/bin/env sh
# tests/smoke/smoke-test.sh
set -eu

echo "[SMOKE] Build tag=${IMAGE_TAG:-local}"
HOST_HTTP_PORT=${HOST_HTTP_PORT:-18080}
SMOKE_REDIS_PORT=${SMOKE_REDIS_PORT:-16379}

echo "[SMOKE] Lancement Redis temporaire sur port ${SMOKE_REDIS_PORT}..."
docker run -d --rm --name redis-smoke -p ${SMOKE_REDIS_PORT}:6379 redis:7-alpine

echo "[SMOKE] Lancement de l’application..."
docker run -d --rm --name nrc-smoke \
  --env-file .env.app \
  --add-host=host.docker.internal:host-gateway \
  -e REDIS_URL="redis://host.docker.internal:${SMOKE_REDIS_PORT}" \
  -p ${HOST_HTTP_PORT}:3000 \
  node-redis-counter:${IMAGE_TAG:-latest}

echo "[SMOKE] Attente readiness (max 30s)..."
for i in $(seq 1 30); do
  if curl -sf "http://localhost:${HOST_HTTP_PORT}/healthz" >/dev/null 2>&1; then
    echo "[SMOKE] ✅ Application prête"
    break
  fi
  sleep 1
  if [ "$i" -eq 30 ]; then
    echo "[SMOKE] ⛔ Timeout readiness"
    docker logs nrc-smoke || true
    docker stop nrc-smoke redis-smoke || true
    exit 1
  fi
done

echo "[SMOKE] Nettoyage..."
docker stop nrc-smoke || true
docker stop redis-smoke || true
echo "[SMOKE] Terminé ✅"
