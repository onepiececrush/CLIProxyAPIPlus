#!/bin/bash

# CLI Proxy API Plus 部署脚本
# 包含前端管理面板打包和后端部署

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/../Cli-Proxy-API-Management-Center"
STATIC_DIR="$SCRIPT_DIR/static"

echo "=========================================="
echo "CLI Proxy API Plus 部署脚本"
echo "=========================================="

# 步骤 1: 打包前端管理面板
echo ""
echo "[1/4] 打包前端管理面板..."
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
echo "[2/4] 复制前端到 static 目录..."
mkdir -p "$STATIC_DIR"
if [ -f "$FRONTEND_DIR/dist/index.html" ]; then
    cp "$FRONTEND_DIR/dist/index.html" "$STATIC_DIR/management.html"
    echo "前端已复制到 $STATIC_DIR/management.html"
else
    echo "警告: 前端打包文件不存在，跳过复制"
fi

# 步骤 3: 构建 Docker 镜像
echo ""
echo "[3/4] 构建 Docker 镜像..."
cd "$SCRIPT_DIR"
docker-compose build

# 步骤 4: 重启容器
echo ""
echo "[4/4] 重启容器..."
docker rm -f cli-proxy-api-plus 2>/dev/null || true
docker-compose up -d

# 等待容器启动
echo ""
echo "等待容器启动..."
sleep 5

# 检查容器状态
if docker ps | grep -q cli-proxy-api-plus; then
    echo ""
    echo "=========================================="
    echo "部署成功!"
    echo "=========================================="
    echo "管理面板: http://localhost:8317/management.html"
    echo ""
    docker logs cli-proxy-api-plus --tail 5
else
    echo ""
    echo "=========================================="
    echo "部署失败! 请检查日志"
    echo "=========================================="
    docker logs cli-proxy-api-plus --tail 20
    exit 1
fi
