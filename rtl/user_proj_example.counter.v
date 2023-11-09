// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

`define MPRJ_IO_PADS_1 19	/* number of user GPIO pads on user1 side */
`define MPRJ_IO_PADS_2 19	/* number of user GPIO pads on user2 side */
`define MPRJ_IO_PADS (`MPRJ_IO_PADS_1 + `MPRJ_IO_PADS_2)

module user_proj_example #(
   parameter BITS = 32,
   parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
   inout vccd1,	// User area 1 1.8V supply
   inout vssd1,	// User area 1 digital ground
`endif

   // Wishbone Slave ports (WB MI A)
   input wb_clk_i,
   input wb_rst_i,
   input wbs_stb_i,
   input wbs_cyc_i,
   input wbs_we_i,
   input [3:0] wbs_sel_i,
   input [31:0] wbs_dat_i,
   input [31:0] wbs_adr_i,
   output reg wbs_ack_o,
   output reg [31:0] wbs_dat_o,

   // Logic Analyzer Signals
   input  [127:0] la_data_in,
   output [127:0] la_data_out,
   input  [127:0] la_oenb,

   // IOs
   input  [`MPRJ_IO_PADS-1:0] io_in,
   output [`MPRJ_IO_PADS-1:0] io_out,
   output [`MPRJ_IO_PADS-1:0] io_oeb,

   // IRQ
   output [2:0] irq
);
   wire clk;

   wire [`MPRJ_IO_PADS-1:0] io_in;
   wire [`MPRJ_IO_PADS-1:0] io_out;
   wire [`MPRJ_IO_PADS-1:0] io_oeb;
   
   reg axi_stb_i;
   reg axi_cyc_i;
   reg axi_we_i;
   reg [31:0] axi_dat_i;
   reg [31:0] axi_adr_i;
   wire axi_ack_o;
   wire [31:0] axi_dat_o;
   
   wire [ 3:0] bram_we;
   reg  [31:0] bram_dat_i;
   reg  [31:0] bram_adr_i;
   reg         bram_ack_o;
   wire [31:0] bram_dat_o;
   
   reg decode;
   
   reg [3:0] cnt;
   always@(posedge wb_clk_i) begin
      if(wb_rst_i) cnt <= 4'd1;
      else if(wbs_ack_o == 1)
         cnt <= 4'd1;
      else if(wbs_cyc_i == 1 && cnt == 4'd1)
         cnt <= cnt + 4'd1;
      else if(cnt == 4'd12)
         cnt <= cnt;
      else if(cnt != 4'd1)
         cnt <= cnt + 4'd1;
   end

   always@(*) begin
      if(cnt == 12)
         bram_ack_o = 1;
      else
         bram_ack_o = 0;
   end

   assign bram_we = cnt>=4'd10 ? {4{wbs_we_i}} : 0;
   
   always@(*) begin
      if(wbs_adr_i[31:24] == 8'h30)
         decode = 1;
      else if(wbs_adr_i[31:24] == 8'h38)
         decode = 0;
      else
         decode = 0;
   end
   
   always@(*) begin
      case(decode)
         1: begin
               axi_stb_i  = wbs_stb_i;
               axi_cyc_i  = wbs_cyc_i;
               axi_we_i   = wbs_we_i;
               axi_dat_i  = wbs_dat_i;
               axi_adr_i  = wbs_adr_i;
               
               wbs_ack_o  = axi_ack_o;
               wbs_dat_o  = axi_dat_o;
               
               bram_dat_i = 0;
               bram_adr_i = 0;
            end   
         0: begin
               axi_stb_i  = 0;
               axi_cyc_i  = 0;
               axi_we_i   = 0;
               axi_dat_i  = 0;
               axi_adr_i  = 0;
               
               wbs_ack_o  = bram_ack_o;
               wbs_dat_o  = bram_dat_o;
               
               bram_dat_i = wbs_dat_i;
               bram_adr_i = wbs_adr_i;
            end
      endcase
   end
   
   bram user_bram (
     .CLK(wb_clk_i),
     .WE0(bram_we),
     .EN0(~wb_rst_i),
     .Di0(bram_dat_i),
     .Do0(bram_dat_o),
     .A0(bram_adr_i)
   );
   
   wb_axi U1 (
      .clk(wb_clk_i),
      .wb_rst_i(wb_rst_i),
      .wbs_stb_i(axi_stb_i),
      .wbs_cyc_i(axi_cyc_i),
      .wbs_we_i(axi_we_i),
      .wbs_dat_i(axi_dat_i),
      .wbs_adr_i(axi_adr_i),
      .wbs_ack_o(axi_ack_o),
      .wbs_dat_o(axi_dat_o)
   );


endmodule




