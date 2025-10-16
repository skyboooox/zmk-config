#!/bin/bash
#
# ZMK 固件刷写脚本
# 将编译好的固件刷写到 nice!nano v2
#

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
BOARD="nice_nano_v2"
SHIELD="ssd1681_154"
FIRMWARE_FILE="$HOME/zmk_${BOARD}_${SHIELD}.uf2"
MOUNT_POINT="/media/$USER/NICENANO"
TIMEOUT=60  # 等待设备的超时时间(秒)

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  ZMK 固件刷写脚本${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# 检查固件文件是否存在
if [ ! -f "$FIRMWARE_FILE" ]; then
    echo -e "${RED}✗ 错误: 未找到固件文件${NC}"
    echo -e "  期望位置: ${YELLOW}$FIRMWARE_FILE${NC}"
    echo ""
    echo -e "${YELLOW}请先运行 ./build.sh 编译固件${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 找到固件文件:${NC}"
echo -e "  ${CYAN}$FIRMWARE_FILE${NC}"
echo -e "  大小: ${YELLOW}$(ls -lh $FIRMWARE_FILE | awk '{print $5}')${NC}"
echo ""

# 显示操作说明
echo -e "${YELLOW}请执行以下步骤进入引导模式:${NC}"
echo ""
echo -e "  1. 在 nice!nano 板上找到 ${CYAN}RESET${NC} 按钮"
echo -e "  2. 快速按 ${CYAN}两次${NC} RESET 按钮 (双击)"
echo -e "     ${YELLOW}或${NC} 用镊子短接 ${CYAN}RST${NC} 和 ${CYAN}GND${NC} 两次"
echo ""
echo -e "  3. 板载 LED 会开始呼吸闪烁(蓝色)"
echo -e "  4. 电脑会识别出 ${CYAN}NICENANO${NC} USB 驱动器"
echo ""

# 等待用户操作
read -p "按 Enter 继续,等待设备进入引导模式... " -r
echo ""

# 等待设备挂载
echo -e "${YELLOW}等待 NICENANO 设备...${NC}"
ELAPSED=0
FOUND=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # 检查多种可能的挂载点
    for MOUNT_CHECK in "/media/$USER/NICENANO" "/media/NICENANO" "/run/media/$USER/NICENANO" "/mnt/NICENANO"; do
        if [ -d "$MOUNT_CHECK" ]; then
            MOUNT_POINT="$MOUNT_CHECK"
            FOUND=1
            break 2
        fi
    done
    
    # 检查 /dev 中是否出现新的块设备
    if ls /dev/sd* 2>/dev/null | grep -q "sd[a-z]$"; then
        echo -e "${CYAN}检测到 USB 存储设备...${NC}"
    fi
    
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    
    # 显示进度
    if [ $((ELAPSED % 5)) -eq 0 ]; then
        echo -e "${YELLOW}  已等待 ${ELAPSED}/${TIMEOUT} 秒...${NC}"
    fi
done

if [ $FOUND -eq 0 ]; then
    echo ""
    echo -e "${RED}✗ 超时: 未检测到 NICENANO 设备${NC}"
    echo ""
    echo -e "${YELLOW}故障排除:${NC}"
    echo -e "  • 确认已按两次 RESET 按钮"
    echo -e "  • 检查 USB 数据线是否连接(需要支持数据传输)"
    echo -e "  • 尝试更换 USB 端口"
    echo -e "  • 检查 dmesg 输出: ${CYAN}dmesg | tail -20${NC}"
    echo -e "  • 手动挂载设备后运行: ${CYAN}./flash.sh --manual${NC}"
    echo ""
    exit 1
fi

# 找到设备
echo ""
echo -e "${GREEN}✓ 检测到 NICENANO 设备${NC}"
echo -e "  挂载点: ${CYAN}$MOUNT_POINT${NC}"
echo ""

# 显示设备信息
if [ -f "$MOUNT_POINT/INFO_UF2.TXT" ]; then
    echo -e "${BLUE}设备信息:${NC}"
    cat "$MOUNT_POINT/INFO_UF2.TXT" | grep -E "Model|Board-ID" | sed 's/^/  /'
    echo ""
fi

# 检查是否有写权限
if [ ! -w "$MOUNT_POINT" ]; then
    echo -e "${YELLOW}需要管理员权限写入设备...${NC}"
    USE_SUDO="sudo"
else
    USE_SUDO=""
fi

# 复制固件
echo -e "${GREEN}正在刷写固件...${NC}"
echo -e "${YELLOW}请勿断开 USB 连接!${NC}"
echo ""

$USE_SUDO cp -v "$FIRMWARE_FILE" "$MOUNT_POINT/"

# 等待写入完成
sync
sleep 2

echo ""
echo -e "${GREEN}✓ 固件刷写完成!${NC}"
echo ""

# 设备应该会自动重启并卸载
echo -e "${YELLOW}设备将自动重启...${NC}"
sleep 3

# 检查设备是否已卸载(表示重启成功)
if [ ! -d "$MOUNT_POINT" ]; then
    echo -e "${GREEN}✓ 设备已重启${NC}"
else
    echo -e "${YELLOW}等待设备卸载...${NC}"
    ELAPSED=0
    while [ -d "$MOUNT_POINT" ] && [ $ELAPSED -lt 10 ]; do
        sleep 1
        ELAPSED=$((ELAPSED + 1))
    done
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}刷写完成!${NC}"
echo ""
echo -e "${YELLOW}硬件连接检查清单:${NC}"
echo -e "  ${CYAN}□${NC} VCC  → 3.3V"
echo -e "  ${CYAN}□${NC} GND  → GND"
echo -e "  ${CYAN}□${NC} MOSI → MOSI (P0.10)"
echo -e "  ${CYAN}□${NC} SCK  → SCK  (P1.13)"
echo -e "  ${CYAN}□${NC} DC   → A1/D19 (P0.02)"
echo -e "  ${CYAN}□${NC} RST  → A2/D20 (P0.29)"
echo -e "  ${CYAN}□${NC} BUSY → A3/D21 (P0.31)"
echo ""
echo -e "${GREEN}下一步:${NC}"
echo -e "  • 设备应该已经运行新固件"
echo -e "  • SSD1681 显示屏应该开始初始化"
echo -e "  • 如需查看串口日志:"
echo -e "    ${CYAN}sudo screen /dev/ttyACM0 115200${NC}"
echo -e "    ${YELLOW}(按 Ctrl+A 然后 K 退出 screen)${NC}"
echo ""
echo -e "${BLUE}================================================${NC}"
