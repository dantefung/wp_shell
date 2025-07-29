#!/bin/bash

set -e

# 默认 compose 文件名
COMPOSE_FILE="docker-compose.yml"

# 支持 -f 指定 compose 文件
while getopts "f:" opt; do
  case $opt in
    f) COMPOSE_FILE="$OPTARG"
    ;;
    *) echo "Usage: $0 [-f docker-compose.yml]"; exit 1
    ;;
  esac
done

echo "🔍 Using compose file: $COMPOSE_FILE"

# 检查文件是否存在
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ Compose file not found: $COMPOSE_FILE"
  exit 1
fi

echo "🔧 Disabling restart policy for running containers..."
# 获取当前 compose 项目下的容器 ID
CONTAINER_IDS=$(docker compose -f "$COMPOSE_FILE" ps -q)

if [ -z "$CONTAINER_IDS" ]; then
  echo "ℹ️ No running containers found for this compose project."
else
  for cid in $CONTAINER_IDS; do
    echo "➡️ Disabling restart for container: $cid"
    docker update --restart=no "$cid"
  done
fi

echo "📦 Bringing down existing containers..."
docker compose -f "$COMPOSE_FILE" down

echo "🚀 Recreating containers with new config..."
docker compose -f "$COMPOSE_FILE" up -d

echo "✅ Done. Containers restarted with updated configuration."
	
