/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef _CARAVEL_H_
#define _CARAVEL_H_

#include <stdint.h>
#include <stdbool.h>

//lab4-2
#define reg_fir_control (*(volatile uint32_t*)0x30000000)
#define reg_fir_datalen (*(volatile uint32_t*)0x30000010)
#define reg_fir_coeff   (*(volatile uint32_t*)0x30000040)

// User Project Control (0x2300_0000)
#define reg_mprj_xfer (*(volatile uint32_t*)0x26000000)
#define reg_mprj_pwr  (*(volatile uint32_t*)0x26000004)
#define reg_mprj_irq  (*(volatile uint32_t*)0x26100014)
#define reg_mprj_datal (*(volatile uint32_t*)0x2600000c)
#define reg_mprj_datah (*(volatile uint32_t*)0x26000010)

#define reg_mprj_io_0 (*(volatile uint32_t*)0x26000024)
#define reg_mprj_io_1 (*(volatile uint32_t*)0x26000028)
#define reg_mprj_io_2 (*(volatile uint32_t*)0x2600002c)
#define reg_mprj_io_3 (*(volatile uint32_t*)0x26000030)
#define reg_mprj_io_4 (*(volatile uint32_t*)0x26000034)
#define reg_mprj_io_5 (*(volatile uint32_t*)0x26000038)
#define reg_mprj_io_6 (*(volatile uint32_t*)0x2600003c)

#define reg_mprj_io_7 (*(volatile uint32_t*)0x26000040)
#define reg_mprj_io_8 (*(volatile uint32_t*)0x26000044)
#define reg_mprj_io_9 (*(volatile uint32_t*)0x26000048)
#define reg_mprj_io_10 (*(volatile uint32_t*)0x2600004c)

#define reg_mprj_io_11 (*(volatile uint32_t*)0x26000050)
#define reg_mprj_io_12 (*(volatile uint32_t*)0x26000054)
#define reg_mprj_io_13 (*(volatile uint32_t*)0x26000058)
#define reg_mprj_io_14 (*(volatile uint32_t*)0x2600005c)

#define reg_mprj_io_15 (*(volatile uint32_t*)0x26000060)
#define reg_mprj_io_16 (*(volatile uint32_t*)0x26000064)
#define reg_mprj_io_17 (*(volatile uint32_t*)0x26000068)
#define reg_mprj_io_18 (*(volatile uint32_t*)0x2600006c)

#define reg_mprj_io_19 (*(volatile uint32_t*)0x26000070)
#define reg_mprj_io_20 (*(volatile uint32_t*)0x26000074)
#define reg_mprj_io_21 (*(volatile uint32_t*)0x26000078)
#define reg_mprj_io_22 (*(volatile uint32_t*)0x2600007c)

#define reg_mprj_io_23 (*(volatile uint32_t*)0x26000080)
#define reg_mprj_io_24 (*(volatile uint32_t*)0x26000084)
#define reg_mprj_io_25 (*(volatile uint32_t*)0x26000088)
#define reg_mprj_io_26 (*(volatile uint32_t*)0x2600008c)

#define reg_mprj_io_27 (*(volatile uint32_t*)0x26000090)
#define reg_mprj_io_28 (*(volatile uint32_t*)0x26000094)
#define reg_mprj_io_29 (*(volatile uint32_t*)0x26000098)
#define reg_mprj_io_30 (*(volatile uint32_t*)0x2600009c)
#define reg_mprj_io_31 (*(volatile uint32_t*)0x260000a0)

#define reg_mprj_io_32 (*(volatile uint32_t*)0x260000a4)
#define reg_mprj_io_33 (*(volatile uint32_t*)0x260000a8)
#define reg_mprj_io_34 (*(volatile uint32_t*)0x260000ac)
#define reg_mprj_io_35 (*(volatile uint32_t*)0x260000b0)
#define reg_mprj_io_36 (*(volatile uint32_t*)0x260000b4)
#define reg_mprj_io_37 (*(volatile uint32_t*)0x260000b8)

// Housekeeping
#define reg_hkspi_status      (*(volatile uint32_t*)0x26100000)
#define reg_hkspi_chip_id     (*(volatile uint32_t*)0x26100004)
#define reg_hkspi_user_id     (*(volatile uint32_t*)0x26100008)
#define reg_hkspi_pll_ena     (*(volatile uint32_t*)0x2610000c)
#define reg_hkspi_pll_bypass  (*(volatile uint32_t*)0x26100010)
#define reg_hkspi_irq 	      (*(volatile uint32_t*)0x26100014)
#define reg_hkspi_reset       (*(volatile uint32_t*)0x26100018)
#define reg_hkspi_trap 	      (*(volatile uint32_t*)0x26100028)
#define reg_hkspi_pll_trim    (*(volatile uint32_t*)0x2610001c)
#define reg_hkspi_pll_source  (*(volatile uint32_t*)0x26100020)
#define reg_hkspi_pll_divider (*(volatile uint32_t*)0x26100024)
#define reg_hkspi_disable     (*(volatile uint32_t*)0x26200010)

// System Area (0x2620_0000)
#define reg_power_good    (*(volatile uint32_t*)0x26200000)
#define reg_clk_out_dest  (*(volatile uint32_t*)0x26200004)
#define reg_trap_out_dest (*(volatile uint32_t*)0x26200004)
#define reg_irq_source    (*(volatile uint32_t*)0x2620000C)

// Bit fields for reg_power_good
#define USER1_VCCD_POWER_GOOD 0x01
#define USER2_VCCD_POWER_GOOD 0x02
#define USER1_VDDA_POWER_GOOD 0x04
#define USER2_VDDA_POWER_GOOD 0x08

// Bit fields for reg_clk_out_dest
#define CLOCK1_MONITOR 0x01
#define CLOCK2_MONITOR 0x02
#define TRAP_MONITOR 0x04

// Bit fields for reg_irq_source
#define IRQ7_SOURCE 0x01
#define IRQ8_SOURCE 0x02

// Individual bit fields for the GPIO pad control
#define MGMT_ENABLE	  0x0001
#define OUTPUT_DISABLE	  0x0002
#define HOLD_OVERRIDE	  0x0004
#define INPUT_DISABLE	  0x0008
#define MODE_SELECT	  0x0010
#define ANALOG_ENABLE	  0x0020
#define ANALOG_SELECT	  0x0040
#define ANALOG_POLARITY	  0x0080
#define SLOW_SLEW_MODE	  0x0100
#define TRIPPOINT_SEL	  0x0200
#define DIGITAL_MODE_MASK 0x1c00

// Useful GPIO mode values
#define GPIO_MODE_MGMT_STD_INPUT_NOPULL    0x0403
#define GPIO_MODE_MGMT_STD_INPUT_PULLDOWN  0x0c01
#define GPIO_MODE_MGMT_STD_INPUT_PULLUP	   0x0801
#define GPIO_MODE_MGMT_STD_OUTPUT	   0x1809
#define GPIO_MODE_MGMT_STD_BIDIRECTIONAL   0x1801
#define GPIO_MODE_MGMT_STD_ANALOG   	   0x000b

#define GPIO_MODE_USER_STD_INPUT_NOPULL	   0x0402
#define GPIO_MODE_USER_STD_INPUT_PULLDOWN  0x0c00
#define GPIO_MODE_USER_STD_INPUT_PULLUP	   0x0800
#define GPIO_MODE_USER_STD_OUTPUT	   0x1808
#define GPIO_MODE_USER_STD_BIDIRECTIONAL   0x1800
#define GPIO_MODE_USER_STD_OUT_MONITORED   0x1802
#define GPIO_MODE_USER_STD_ANALOG   	   0x000a

// --------------------------------------------------------
#endif
