#!/bin/bash

# CLI Proxy API Plus 远程部署脚本
# 本地构建 Docker 镜像后上传到服务器

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_IP="1.15.137.13"
SERVER_USER="root"
IMAGE_NAME="cli-proxy-api-plus"
IMAGE_TAG="latest"
IMAGE_FILE="${IMAGE_NAME}-${IMAGE_TAG}.tar.gz"
REMOTE_DIR="/root/cli-proxy-api-plus"

echo "=========================================="
echo "CLI Proxy API Plus 远程部署脚本"
echo "=========================================="
echo "服务器: ${SERVER_USER}@${SERVER_IP}"
echo ""

# 步骤 1: 打包前端管理面板
echo "[1/6] 打包前端管理面板..."
FRONTEND_DIR="$SCRIPT_DIR/../Cli-Proxy-API-Management-Center"
STATIC_DIR="$SCRIPT_DIR/static"
if [ -d "$FRONTEND_DIR" ]; then
    cd "$FRONTEND_DIR"
    npm run build
    echo "前端打包完成"
else
    echo "警告: 前端目录不存在: $FRONTEND_DIR"
    echo "跳过前端打包"
fi

# 步骤 2: 复制前端到 static 目录
echo ""
echo "[2/6] 复制前端到 static 目录..."
mkdir -p "$STATIC_DIR"
if [ -f "$FRONTEND_DIR/dist/index.html" ]; then
    cp "$FRONTEND_DIR/dist/index.html" "$STATIC_DIR/management.html"
    echo "前端已复制到 $STATIC_DIR/management.html"
else
    echo "警告: 前端打包文件不存在，跳过复制"
fi

# 步骤 3: 构建 Docker 镜像 (AMD64 架构，适配服务器)
echo ""
echo "[3/6] 构建 Docker 镜像 (AMD64)..."
cd "$SCRIPT_DIR"
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
docker buildx build --platform linux/amd64 \
  --build-arg VERSION=${VERSION} \
  --build-arg COMMIT=${COMMIT} \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  -t ${IMAGE_NAME}:${IMAGE_TAG} . --load

# 步骤 4: 导出 Docker 镜像
echo ""
echo "[4/6] 导出 Docker 镜像..."
docker save ${IMAGE_NAME}:${IMAGE_TAG} | gzip > ${IMAGE_FILE}
echo "镜像已导出到: ${IMAGE_FILE}"

# 步骤 5: 上传到服务器
echo ""
echo "[5/6] 上传文件到服务器..."
# 创建远程目录
ssh ${SERVER_USER}@${SERVER_IP} "mkdir -p ${REMOTE_DIR}/{auths,logs,static}"

# 上传镜像文件
echo "上传镜像文件..."
scp ${IMAGE_FILE} ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/

# 上传配置文件
echo "上传配置文件..."
scp config.yaml ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/ 2>/dev/null || echo "警告: config.yaml 不存在，请手动配置"

# 上传静态文件
echo "上传静态文件..."
scp -r static/* ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/static/ 2>/dev/null || echo "警告: static 目录为空"

# 上传认证文件
echo "上传认证文件..."
scp auths/*.json ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/auths/ 2>/dev/null && echo "已上传 $(ls auths/*.json 2>/dev/null | wc -l) 个认证文件" || echo "警告: 没有找到认证文件"

# 上传 docker-compose.yml
echo "上传 docker-compose.yml..."
cat > /tmp/docker-compose-remote.yml << 'EOF'
services:
  cli-proxy-api:
    image: cli-proxy-api-plus:latest
    container_name: cli-proxy-api-plus
    environment:
      DEPLOY: production
      MANAGEMENT_STATIC_PATH: /CLIProxyAPI/static/management.html
    ports:
      - "8317:8317"
      - "8085:8085"
      - "1455:1455"
      - "54545:54545"
      - "51121:51121"
      - "11451:11451"
    volumes:
      - ./config.yaml:/CLIProxyAPI/config.yaml
      - ./auths:/root/.cli-proxy-api
      - ./logs:/CLIProxyAPI/logs
      - ./static:/CLIProxyAPI/static
    restart: unless-stopped
EOF
scp /tmp/docker-compose-remote.yml ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/docker-compose.yml

# 步骤 6: 在服务器上部署
echo ""
echo "[6/6] 在服务器上部署..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /root/cli-proxy-api-plus

# 停止并删除旧容器
echo "停止旧容器..."
docker rm -f cli-proxy-api-plus 2>/dev/null || true

# 导入新镜像
echo "导入新镜像..."
gunzip -c cli-proxy-api-plus-latest.tar.gz | docker load

# 启动新容器
echo "启动新容器..."
docker compose up -d

# 等待容器启动
sleep 5

# 检查容器状态
echo ""
echo "=========================================="
if docker ps | grep -q cli-proxy-api-plus; then
    echo "部署成功!"
    echo "=========================================="
    echo "管理面板: http://1.15.137.13:8317/management.html"
    echo ""
    docker logs cli-proxy-api-plus --tail 10
else
    echo "部署失败! 请检查日志"
    echo "=========================================="
    docker logs cli-proxy-api-plus --tail 20
    exit 1
fi
ENDSSH

# 清理本地镜像文件
echo ""
echo "清理本地镜像文件..."
rm ${IMAGE_FILE}
rm /tmp/docker-compose-remote.yml

echo ""
echo "=========================================="
echo "部署完成!"
echo "=========================================="
