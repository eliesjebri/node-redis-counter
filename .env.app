# Port écouté DANS le conteneur (l'app lit PORT)
PORT=3000

# Redis accessible depuis le conteneur de l'app
# - Si Redis tourne sur la machine hôte: expose-le sur 6379 et utilise host.docker.internal
# - Sinon mets l'URL de ton Redis managé (ex: redis://user:pass@host:6379/0)
REDIS_URL=redis://host.docker.internal:6379

# Clé du compteur dans Redis (pour isoler tes runs)
COUNTER_KEY=global:hits

# Métadonnées affichées par l'API
SERVICE_NAME=node-redis-counter
SERVICE_VERSION=1.0.0
