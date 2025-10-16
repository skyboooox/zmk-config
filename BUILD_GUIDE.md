# ZMK 固件构建指南

本项目为 nice!nano v2 + SSD1681 1.54" 电子纸显示屏提供 ZMK 固件支持。

## 📋 目录结构

```
zmk-config/
├── build.sh                    # 编译脚本
├── flash.sh                    # 刷写脚本
├── boards/shields/ssd1681_154/ # 显示屏 shield 定义
├── config/                     # 键盘布局和配置
└── build/                      # 编译输出 (自动生成)
```

## 🚀 快速开始

### 1. 编译固件

```bash
# 基本编译
./build.sh

# 清理后重新编译
./build.sh clean

# 更新依赖后编译
./build.sh update
```

**编译选项:**
- `./build.sh` - 正常编译
- `./build.sh clean` 或 `./build.sh -c` - 清理后编译
- `./build.sh update` 或 `./build.sh -u` - 更新 west 依赖

**编译时间:** 首次编译约 3-5 分钟,后续增量编译约 30 秒

**输出位置:**
- `build/zephyr/zmk.uf2` - 构建目录
- `~/zmk_nice_nano_v2_ssd1681.uf2` - 用户主目录(方便使用)

### 2. 刷写固件

```bash
./flash.sh
```

**刷写步骤:**

1. 运行 `./flash.sh`
2. 按照提示,在 nice!nano 上快速按两次 RESET 按钮
3. 等待设备识别为 NICENANO 驱动器
4. 脚本会自动复制固件并重启设备

**手动刷写:**
```bash
# 如果自动刷写失败,可以手动操作:
# 1. 双击 RESET 进入引导模式
# 2. 找到 NICENANO 驱动器
# 3. 复制固件
cp ~/zmk_nice_nano_v2_ssd1681.uf2 /media/$USER/NICENANO/
```

## 🔌 硬件连接

### nice!nano v2 ↔ SSD1681 显示屏

| SSD1681 | nice!nano | nRF52840 | 功能         |
|---------|-----------|----------|--------------|
| VCC     | 3.3V      | -        | 电源 3.3V    |
| GND     | GND       | -        | 地线         |
| DIN     | MOSI      | P0.10    | SPI 数据     |
| CLK     | SCK       | P1.13    | SPI 时钟     |
| CS      | (自动)    | -        | SPI 片选     |
| DC      | A1 (D19)  | P0.02    | 数据/命令    |
| RST     | A2 (D20)  | P0.29    | 复位         |
| BUSY    | A3 (D21)  | P0.31    | 忙碌信号     |

**重要提示:**
- ⚠️ 必须使用 **3.3V** 电源,不要使用 5V
- ⚠️ SPI 频率设置为 4MHz
- ⚠️ BUSY 引脚配置为 HIGH 有效

### 引脚图参考

```
nice!nano v2 (顶视图)
    USB
     |
  [=====]
  | D1  |---- GND
  | D0  |---- RST
  | GND |---- VCC
  | GND |---- A3 (D21) --> BUSY
  | D2  |---- A2 (D20) --> RST
  | D3  |---- A1 (D19) --> DC
  | D4  |
  | D5  |
  ...
```

## 🛠️ 依赖环境

### 必需软件

- **Docker** - 用于编译环境
  ```bash
  # Ubuntu/Debian
  sudo apt install docker.io
  sudo usermod -aG docker $USER
  
  # 重新登录后生效
  ```

- **Git** (可选) - 用于版本管理
  ```bash
  sudo apt install git
  ```

### Docker 镜像

脚本会自动拉取 `zmkfirmware/zmk-build-arm:stable` 镜像(约 2.3 GB)

## 📝 配置文件说明

### 键盘配置

- **config/ssd1681_154.keymap** - 键盘布局 (最小 1x1 配置)
- **config/ssd1681_154.conf** - 显示屏功能配置

### Shield 定义

- **boards/shields/ssd1681_154/ssd1681_154.overlay** - 硬件连接 DTS
- **boards/shields/ssd1681_154/Kconfig.defconfig** - 默认配置
- **boards/shields/ssd1681_154/Kconfig.shield** - Shield 选择

## 🔧 自定义修改

### 修改显示屏配置

编辑 `config/ssd1681_154.conf`:

```kconfig
# 显示超时 (毫秒)
CONFIG_ZMK_IDLE_TIMEOUT=30000

# 启用显示
CONFIG_ZMK_DISPLAY=y
```

### 修改 SPI 频率

编辑 `boards/shields/ssd1681_154/ssd1681_154.overlay`:

```dts
spi-max-frequency = <4000000>;  // 4MHz,可改为 2000000 (2MHz)
```

### 修改 BUSY 引脚极性

如果显示屏 BUSY 信号为低电平有效:

```dts
busy-gpios = <&pro_micro 21 GPIO_ACTIVE_LOW>;  // 改为 LOW
```

## 📊 编译输出

成功编译后会显示:

```
Memory region         Used Size  Region Size  %age Used
           FLASH:      280020 B       792 KB     34.53%
             RAM:       53712 B       256 KB     20.49%
```

## 🐛 故障排除

### 编译失败

**问题:** Docker 权限错误
```bash
# 解决方法:
sudo usermod -aG docker $USER
# 重新登录
```

**问题:** 网络超时
```bash
# 使用 --network host
# (脚本已默认使用)
```

### 刷写失败

**问题:** 未检测到 NICENANO 设备

1. 检查 USB 线是否支持数据传输
2. 尝试不同的 USB 端口
3. 查看系统日志:
   ```bash
   dmesg | tail -20
   ```

**问题:** 设备显示为只读

```bash
# 检查挂载点权限
ls -l /media/$USER/NICENANO

# 可能需要使用 sudo
sudo cp ~/zmk_nice_nano_v2_ssd1681.uf2 /media/$USER/NICENANO/
```

### 显示屏无反应

1. **检查连线** - 使用万用表验证连接
2. **检查电压** - 确保 3.3V 电源
3. **检查 BUSY 极性** - 尝试改为 ACTIVE_LOW
4. **查看串口日志:**
   ```bash
   sudo screen /dev/ttyACM0 115200
   # 按 Ctrl+A 然后 K 退出
   ```

## 📚 参考资源

- [ZMK 官方文档](https://zmk.dev/)
- [nice!nano 引脚定义](https://nicekeyboards.com/docs/nice-nano/pinout-schematic)
- [SSD1681 数据手册](https://www.good-display.com/companyfile/32.html)
- [Zephyr RTOS 文档](https://docs.zephyrproject.org/)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!

## 📄 许可证

MIT License

---

**制作:** ZMK Community  
**更新时间:** 2025-10-16
