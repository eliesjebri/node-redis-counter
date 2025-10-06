#!/usr/bin/env sh
set -eu

echo "[IT] Build image for test..."
docker build -t node-redis-counter:test .

echo "[IT] Up compose..."
docker compose -f docker-compose.test.yml up -d

echo "[IT] Wait app readiness..."
# simple retry loop
for i in $(seq 1 30); do
  if curl -sf http://localhost:8080/healthz >/dev/null; then
    break
  fi
  sleep 1
done

echo "[IT] Call #1"
R1=$(curl -s http://localhost:8080/ | sed -n 's/.*"count":\([0-9]\+\).*/\1/p')
echo "count1=$R1"

echo "[IT] Call #2"
R2=$(curl -s http://localhost:8080/ | sed -n 's/.*"count":\([0-9]\+\).*/\1/p')
echo "count2=$R2"

if [ -z "${R1}" ] || [ -z "${R2}" ]; then
  echo "❌ Impossible de parser le compteur"
  docker compose -f docker-compose.test.yml logs app
  exit 1
fi

if [ "$R2" -gt "$R1" ]; then
  echo "✅ Compteur Redis OK ($R1 -> $R2)"
  RC=0
else
  echo "❌ Compteur n'a pas augmenté ($R1 -> $R2)"
  RC=2
fi

echo "[IT] Down compose..."
docker compose -f docker-compose.test.yml down -v || true
exit $RC
