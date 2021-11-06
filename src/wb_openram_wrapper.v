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

`default_nettype none

module wb_openram_wrapper 
#(
    parameter WB0_BASE_ADDR = 32'h3000_0000,
    parameter WB1_BASE_ADDR = 32'h3000_0000,
    parameter ADDR_WIDTH = 8
)
(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Select writable WB port
    input           writable_port;

    // Wishbone port 0
    input           wb0_clk_i,
    input           wb0_rst_i,
    input           wbs0_stb_i,
    input           wbs0_cyc_i,
    input           wbs0_we_i,
    input   [3:0]   wbs0_sel_i,
    input   [31:0]  wbs0_dat_i,
    input   [31:0]  wbs0_adr_i,
    output          wbs0_ack_o,
    output  [31:0]  wbs0_dat_o,

    // Wishbone port 1
    input           wb1_clk_i,
    input           wb1_rst_i,
    input           wbs1_stb_i,
    input           wbs1_cyc_i,
    input           wbs1_we_i,
    input   [3:0]   wbs1_sel_i,
    input   [31:0]  wbs1_dat_i,
    input   [31:0]  wbs1_adr_i,
    output          wbs1_ack_o,
    output  [31:0]  wbs1_dat_o,

    // OpenRAM interface - almost dual port: RW + R
    // Port 0: RW
    output                      ram_clk0,       // clock
    output                      ram_csb0,       // active low chip select
    output                      ram_web0,       // active low write control
    output  [3:0]              	ram_wmask0,     // write (byte) mask
    output  [ADDR_WIDTH-1:0]    ram_addr0,
    output  [31:0]              ram_din0,       // output = connect to openram input (din)
    input   [31:0]              ram_dout0,      // input = connect to openram output (dout)
    
    // Port 1: R
    output                      ram_clk1,       // clock
    output                      ram_csb1,       // active low chip select
    output  [ADDR_WIDTH-1:0]    ram_addr1,  
    input   [31:0]              ram_dout1       // input = connect to openram output (dout)   
);

wb_channel_control channel0
#(
    .BASE_ADDR(WB0_BASE_ADDR),
    .ADDR_WIDTH(ADDR_WIDTH)
)
(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),	    // User area 1 1.8V supply
    .vssd1 (vssd1),	    // User area 1 digital ground
`endif

    .read_only_i    (writable_port),

    // Wishbone interface
    .wb_clk_i       (wb0_clk_i),
    .wb_rst_i       (wb0_rst_i),
    .wbs_stb_i      (wbs0_stb_i),
    .wbs_cyc_i      (wbs0_cyc_i),
    .wbs_we_i       (wbs0_we_i),
    .wbs_adr_i      (wbs0_adr_i),
    .wbs_ack_o      (wbs0_ack_o),

    // OpenRAM interface
    .ram_csb        (ram_csb0),     // active low chip select
    .ram_web        (ram_web0)      // active low write control
);
   
assign ram_clk0 = wb0_clk_i;
assign ram_wmask0 = wbs0_sel_i;
assign ram_addr0 = wbs0_adr_i[ADDR_WIDTH-1:0];


wb_channel_control channel1
#(
    .BASE_ADDR(WB1_BASE_ADDR),
    .ADDR_WIDTH(ADDR_WIDTH)
)
(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),	    // User area 1 1.8V supply
    .vssd1 (vssd1),	    // User area 1 digital ground
`endif

    .read_only_i    (!writable_port),

    // Wishbone interface
    .wb_clk_i       (wb1_clk_i),
    .wb_rst_i       (wb1_rst_i),
    .wbs_stb_i      (wbs1_stb_i),
    .wbs_cyc_i      (wbs1_cyc_i),
    .wbs_we_i       (wbs1_we_i),
    .wbs_adr_i      (wbs1_adr_i),
    .wbs_ack_o      (wbs1_ack_o),

    // OpenRAM interface
    .ram_csb        (ram_csb1),     // active low chip select
    .ram_web        (ram_web1)      // active low write control
);
   
assign ram_clk1 = wb1_clk_i;
assign ram_wmask0 = wbs1_sel_i;
assign ram_addr0 = wbs1_adr_i[ADDR_WIDTH-1:0];

endmodule	// wb_openram_wrapper

`default_nettype wire
