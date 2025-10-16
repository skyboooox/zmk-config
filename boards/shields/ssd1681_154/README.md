SSD1681 1.54" 200x200 电子纸 Shield (for ZMK)

概述
- 控制器: Solomon SSD1681 (Zephyr 驱动: ssd16xx/ssd16xxfb)
- 接口: SPI (使用 nice!nano 的 Pro Micro 引脚排)
- 分辨率: 200 x 200, 单色 1bpp

设备树与驱动
- 本仓库提供 `boards/shields/ssd1681_154/ssd1681_154.overlay`，兼容 Zephyr v3.2 `solomon,ssd16xxfb` 绑定（ZMK v0.3 基于 Zephyr 3.2）。
- 若你使用更新的 Zephyr（main 分支）且 `ssd16xx` 绑定/驱动改名为 `mipi-dbi` 方案，请将 compatible 调整为 `solomon,ssd16xx` 并去除 `cs-gpios`（改用 SPI 片选），其余属性名基本一致。

默认引脚（可按需修改）
- SPI 总线: `&pro_micro_spi`（映射到 nice!nano 的 SPIM1: SCK=P1.13, MOSI=P0.10, MISO=P1.11）
- CS: D10 → P0.09（`cs-gpios = <&pro_micro 10 GPIO_ACTIVE_LOW>;`）
- DC: A1/D19 → P0.02
- RST: A2/D20 → P0.29
- BUSY: A3/D21 → P0.31

接线说明（nice!nano ↔ SSD1681 模组）
- VCC → 3V3（电子纸逻辑 3.3V）
- GND → GND
- SCK → P1.13（SPI SCK，位于 nice!nano SPI1）
- MOSI → P0.10（SPI MOSI）
- MISO → P1.11（SPI MISO；如使用 3 线接口可不接）
- CS → P0.09（Pro Micro D10）
- DC → P0.02（Pro Micro A1/D19）
- RST → P0.29（Pro Micro A2/D20）
- BUSY → P0.31（Pro Micro A3/D21）

构建
- 组合构建（示例）：`-DSHIELD=ssd1681_154 -DBOARD=nice_nano_v2`
- 也可将本 shield 添加到 `build.yaml` 的 include 矩阵进行 CI 构建。

注意
- 电子纸刷新较慢，建议使用 ZMK 的专用显示工作队列；本 shield 的 `Kconfig.defconfig` 已设置默认值。
- 部分 SSD1681 面板 busy 引脚为低有效（本 overlay 假定 ACTIVE_HIGH），若刷新无响应，请将 `busy-gpios` 的极性调整为 `GPIO_ACTIVE_LOW`。
