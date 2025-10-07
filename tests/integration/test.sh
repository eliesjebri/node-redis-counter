#!/usr/bin/env sh
set -eu

echo "[IT] Build image for test..."
docker build -t node-redis-counter:test .

echo "[IT] Load .env variables..."
if [ -f .env ]; then
  echo "[IT] Loading environment variables from .env..."
  while IFS='=' read -r key value; do
    # Ignore lignes vides ou commentées
    first_char=$(printf '%s' "$key" | cut -c1)
    if [ -n "$key" ] && [ "$first_char" != "#" ]; then
      export "$key"="$value"
    fi
  done < .env
fi

# Valeurs par défaut
APP_PORT=${APP_PORT:-3000}
HOST_HTTP_PORT=${HOST_HTTP_PORT:-18080}
REDIS_PORT=${REDIS_PORT:-6379}

echo "[IT] Configuration utilisée :"
echo "  - APP_PORT=${APP_PORT}"
echo "  - HOST_HTTP_PORT=${HOST_HTTP_PORT}"
echo "  - REDIS_PORT=${REDIS_PORT}"

echo "[IT] Up compose environment..."
docker compose -f docker-compose.test.yml up -d

# Déterminer IP du host accessible depuis Jenkins ou Docker DinD
HOST_IP=$(hostname -I | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
  HOST_IP=${HOST_IP:-host.docker.internal}
fi

echo "[IT] Attente du démarrage de l'application (max 90s)..."
for i in $(seq 1 30); do
  if curl -sf "http://${HOST_IP}:${HOST_HTTP_PORT}/healthz" >/dev/null 2>&1; then
    echo "[IT] Application prête ✅"
    break
  fi
  sleep 3
  echo "[IT] Waiting... (${i}s)"
  if [ "$i" -eq 30 ]; then
    echo "[IT] ⛔ Timeout: l'application ne répond pas sur /healthz"
    docker compose -f docker-compose.test.yml logs app || true
    docker compose -f docker-compose.test.yml down -v || true
    exit 1
  fi
done

echo "[IT] Test appel #1"
R1=$(curl -s "http://${HOST_IP}:${HOST_HTTP_PORT}/" | sed -n 's/.*"count":\([0-9]\+\).*/\1/p')
echo "count1=${R1}"

echo "[IT] Test appel #2"
R2=$(curl -s "http://${HOST_IP}:${HOST_HTTP_PORT}/" | sed -n 's/.*"count":\([0-9]\+\).*/\1/p')
echo "count2=${R2}"

if [ -z "${R1}" ] || [ -z "${R2}" ]; then
  echo "❌ Impossible de lire le compteur (valeurs vides)"
  docker compose -f docker-compose.test.yml logs app || true
  docker compose -f docker-compose.test.yml down -v || true
  exit 2
fi

if [ "$R2" -gt "$R1" ]; then
  echo "✅ Compteur Redis OK (le compteur a bien augmenté)"
  RC=0
else
  echo "❌ Compteur Redis non incrémenté"
  docker compose -f docker-compose.test.yml logs app || true
  RC=3
fi

echo "[IT] Nettoyage..."
docker compose -f docker-compose.test.yml down -v || true
exit $RC
