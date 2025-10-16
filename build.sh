#!/bin/bash
#
# ZMK 固件编译脚本
# 使用 Docker 编译 nice!nano v2 + SSD1681 显示屏固件
#

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
DOCKER_IMAGE="zmkfirmware/zmk-build-arm:stable"
BOARD="nice_nano_v2"
SHIELD="ssd1681_154"
OUTPUT_DIR="build/zephyr"
OUTPUT_FILE="zmk.uf2"
FINAL_OUTPUT="/home/user/Documents/zmk-config/zmk_${BOARD}_${SHIELD}.uf2"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  ZMK 固件编译脚本${NC}"
echo -e "${BLUE}  Board: ${BOARD}${NC}"
echo -e "${BLUE}  Shield: ${SHIELD}${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装或未在 PATH 中${NC}"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker 守护进程未运行${NC}"
    echo "请启动 Docker 服务"
    exit 1
fi

# 检查 Docker 镜像
echo -e "${YELLOW}检查 Docker 镜像...${NC}"
if ! docker images | grep -q "zmkfirmware/zmk-build-arm"; then
    echo -e "${YELLOW}Docker 镜像不存在,正在拉取...${NC}"
    sudo docker pull $DOCKER_IMAGE
else
    echo -e "${GREEN}✓ Docker 镜像已存在${NC}"
fi

# 清理旧的构建(可选)
if [ "$1" == "clean" ] || [ "$1" == "-c" ]; then
    echo -e "${YELLOW}清理旧的构建文件...${NC}"
    sudo rm -rf build/
    echo -e "${GREEN}✓ 构建目录已清理${NC}"
fi

# 更新依赖(如果需要)
if [ "$1" == "update" ] || [ "$1" == "-u" ]; then
    echo -e "${YELLOW}更新 west 依赖...${NC}"
    sudo docker run --rm -it \
        --network host \
        -v "$(pwd)":/workspace \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "west update"
    echo -e "${GREEN}✓ 依赖更新完成${NC}"
fi

# 开始编译
echo ""
echo -e "${GREEN}开始编译固件...${NC}"
echo -e "${YELLOW}这可能需要几分钟时间,请耐心等待${NC}"
echo ""

# 执行 Docker 编译
sudo docker run --rm -it \
    --network host \
    -v "$(pwd)":/workspace \
    -w /workspace \
    -e ZEPHYR_BASE=/workspace/zephyr \
    $DOCKER_IMAGE \
    bash -c "west build -p -s zmk/app -b ${BOARD} -- \
        -DSHIELD=${SHIELD} \
        -DBOARD_ROOT=/workspace \
        -DCMAKE_PREFIX_PATH=/workspace/zephyr \
        -DZMK_CONFIG=/workspace/config"

# 检查编译结果
if [ ! -f "$OUTPUT_DIR/$OUTPUT_FILE" ]; then
    echo ""
    echo -e "${RED}✗ 编译失败: 未找到输出文件${NC}"
    exit 1
fi

# 复制固件到用户目录
echo ""
echo -e "${GREEN}✓ 编译成功!${NC}"
sudo cp "$OUTPUT_DIR/$OUTPUT_FILE" "$FINAL_OUTPUT"
sudo chown $USER:$USER "$FINAL_OUTPUT"

# 显示文件信息
echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}固件已生成:${NC}"
echo -e "  位置: ${YELLOW}$FINAL_OUTPUT${NC}"
echo -e "  大小: ${YELLOW}$(ls -lh $FINAL_OUTPUT | awk '{print $5}')${NC}"
echo ""

# 显示内存使用情况
if [ -f "$OUTPUT_DIR/zmk.elf" ]; then
    echo -e "${BLUE}内存使用情况:${NC}"
    sudo docker run --rm \
        -v "$(pwd)":/workspace \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "arm-zephyr-eabi-size build/zephyr/zmk.elf" | tail -2
    echo ""
fi

echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}下一步:${NC}"
echo -e "  运行 ${YELLOW}./flash.sh${NC} 刷写固件到设备"
echo -e "  或手动将 ${YELLOW}$FINAL_OUTPUT${NC} 复制到 NICENANO 驱动器"
echo ""
