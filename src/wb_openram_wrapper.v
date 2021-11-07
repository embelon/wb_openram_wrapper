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
    input           writable_port,

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

// Signals for Channel 0 Control block
wire channel0_rst_i;
wire channel0_stb_i;
wire channel0_cyc_i;
wire channel0_we_i;
wire [31:0] channel0_adr_i;
wire channel0_ack_o;

// Connect signals going from Wishbone 0 or 1 to Channel 0 Control block
assign channel0_rst_i = writable_port ? wb1_rst_i : wb0_rst_i;
assign channel0_stb_i = writable_port ? wbs1_stb_i : wbs0_stb_i;
assign channel0_cyc_i = writable_port ? wbs1_cyc_i : wbs0_cyc_i;
assign channel0_we_i = writable_port ? wbs1_we_i : wbs0_we_i;
assign channel0_adr_i = writable_port ? wbs1_adr_i : wbs0_adr_i;

// Connect signals going directly from Wishbone 0 or 1 to OpenRAM port 0 (RW)
assign ram_clk0 = writable_port ? wb1_clk_i : wb0_clk_i;
assign ram_wmask0 = writable_port ? wbs1_sel_i : wbs0_sel_i;
assign ram_addr0 = channel0_adr_i[ADDR_WIDTH-1:0];
assign ram_din0 = writable_port ? wbs1_dat_i : wbs0_dat_i;

wb_channel_control
#(
    .BASE_ADDR(WB0_BASE_ADDR),
    .ADDR_WIDTH(ADDR_WIDTH),
    .READ_ONLY(0)
) channel0
(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),	    // User area 1 1.8V supply
    .vssd1 (vssd1),	    // User area 1 digital ground
`endif

    // Wishbone interface
    .wb_clk_i       (ram_clk0),
    .wb_rst_i       (channel0_rst_i),
    .wbs_stb_i      (channel0_stb_i),
    .wbs_cyc_i      (channel0_cyc_i),
    .wbs_we_i       (channel0_we_i),
    .wbs_adr_i      (channel0_adr_i),
    .wbs_ack_o      (channel0_ack_o),

    // OpenRAM interface
    .ram_csb        (ram_csb0),     // active low chip select
    .ram_web        (ram_web0)      // active low write control
);



// Signals for Channel 1 Control block
wire channel1_rst_i;
wire channel1_stb_i;
wire channel1_cyc_i;
wire channel1_we_i;
wire [31:0] channel1_adr_i;
wire channel1_ack_o;

// Connect signals going from Wishbone 0 or 1 to Channel 1 Control block
assign channel1_rst_i = !writable_port ? wb1_rst_i : wb0_rst_i;
assign channel1_stb_i = !writable_port ? wbs1_stb_i : wbs0_stb_i;
assign channel1_cyc_i = !writable_port ? wbs1_cyc_i : wbs0_cyc_i;
assign channel1_we_i = !writable_port ? wbs1_we_i : wbs0_we_i;
assign channel1_adr_i = !writable_port ? wbs1_adr_i : wbs0_adr_i;

// Connect signals going directly from Wishbone 0 or 1 to OpenRAM port 1 (R)
assign ram_clk1 = !writable_port ? wb1_clk_i : wb0_clk_i;
assign ram_addr1 = channel1_adr_i[ADDR_WIDTH-1:0];

wb_channel_control 
#(
    .BASE_ADDR(WB1_BASE_ADDR),
    .ADDR_WIDTH(ADDR_WIDTH),
    .READ_ONLY(1)
) channel1
(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),	    // User area 1 1.8V supply
    .vssd1 (vssd1),	    // User area 1 digital ground
`endif

    // Wishbone interface
    .wb_clk_i       (ram_clk1),
    .wb_rst_i       (channel1_rst_i),
    .wbs_stb_i      (channel1_stb_i),
    .wbs_cyc_i      (channel1_cyc_i),
    .wbs_we_i       (channel1_we_i),
    .wbs_adr_i      (channel1_adr_i),
    .wbs_ack_o      (channel1_ack_o),

    // OpenRAM interface
    .ram_csb        (ram_csb1)     // active low chip select
//    .ram_web        ()      // active low write control
);
   

// Connect signals going from OpenRAM port 0 or 1 to Wishbone 0
assign wbs0_dat_o = !writable_port ? ram_dout0 : ram_dout1;
assign wbs0_ack_o = !writable_port ? channel0_ack_o : channel1_ack_o;

// Connect signals going from OpenRAM port 0 or 1 to Wishbone 1
assign wbs1_dat_o = writable_port ? ram_dout0 : ram_dout1;
assign wbs1_ack_o = writable_port ? channel0_ack_o : channel1_ack_o;


endmodule	// wb_openram_wrapper

`default_nettype wire
