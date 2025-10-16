建议接线（nice!nano ⇄ SSD1681 模组）
- 3V3 → VCC
- GND → GND
- P1.13 (SPI SCK) → SCK
- P0.10 (SPI MOSI) → MOSI
- P1.11 (SPI MISO) → MISO（如仅需写入可不接）
- P0.09 (Pro Micro D10) → CS
- P0.02 (Pro Micro A1/D19) → DC
- P0.29 (Pro Micro A2/D20) → RST
- P0.31 (Pro Micro A3/D21) → BUSY

说明
- 上述 Pro Micro 引脚与 nRF52840 实脚对应关系可见 `nice_nano/arduino_pro_micro_pins.dtsi`（ZMK 内置）。
- 若你的面板 BUSY 为低有效，请把 overlay 里的 `busy-gpios` 改为 `GPIO_ACTIVE_LOW`。
- SPI 速率默认 4MHz，可按需下调以提高稳定性。
