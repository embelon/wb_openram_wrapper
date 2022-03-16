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
`timescale 1ns/1ns

module wb_openram_wrapper 
#(
    parameter ADDR_WIDTH = 8
)
(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Select writable WB port
    input           		writable_port_req,
//    output			writable_port_sel,

    // Wishbone port A
    input           		wb_a_clk_i,
    input           		wb_a_rst_i,
    input           		wbs_a_stb_i,
    input           		wbs_a_cyc_i,
    input           		wbs_a_we_i,
    input   [3:0]   		wbs_a_sel_i,
    input   [31:0]  		wbs_a_dat_i,
    input   [ADDR_WIDTH+1:0]  	wbs_a_adr_i,
    output          		wbs_a_ack_o,
    output  [31:0]  		wbs_a_dat_o,

    // Wishbone port B
    input           		wb_b_clk_i,
    input           		wb_b_rst_i,
    input           		wbs_b_stb_i,
    input           		wbs_b_cyc_i,
    input           		wbs_b_we_i,
    input   [3:0]   		wbs_b_sel_i,
    input   [31:0]  		wbs_b_dat_i,
    input   [ADDR_WIDTH+1:0] 	wbs_b_adr_i,
    output          		wbs_b_ack_o,
    output  [31:0]  		wbs_b_dat_o,

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

// Signals for OpenRAM Port 0 Control block
wire port0_clk_i;
wire port0_rst_i;
wire port0_stb_i;
wire port0_cyc_i;
wire port0_we_i;
wire port0_ack_o;
wire [31:0] port0_dat_o;

// Connect signals going from Wishbone A or B to Port 0 Control block
assign port0_clk_i = writable_port_req ? wb_b_clk_i : wb_a_clk_i;
assign port0_rst_i = writable_port_req ? wb_b_rst_i : wb_a_rst_i;
assign port0_stb_i = writable_port_req ? wbs_b_stb_i : wbs_a_stb_i;
assign port0_cyc_i = writable_port_req ? wbs_b_cyc_i : wbs_a_cyc_i;
assign port0_we_i = writable_port_req ? wbs_b_we_i : wbs_a_we_i;

// Connect signals going directly from Wishbone A or B to OpenRAM port 0 (RW)
assign ram_wmask0 = writable_port_req ? wbs_b_sel_i : wbs_a_sel_i;
assign ram_addr0 = writable_port_req ? wbs_b_adr_i[ADDR_WIDTH+1:2] : wbs_a_adr_i[ADDR_WIDTH+1:2];
assign ram_din0 = writable_port_req ? wbs_b_dat_i : wbs_a_dat_i;

wb_port_control
#(
    .READ_ONLY(0),
    .LATENCY_CNTR_WIDTH(4)
) port0_rw
(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),	    // User area 1 1.8V supply
    .vssd1 (vssd1),	    // User area 1 digital ground
`endif

    // configuration for clock stretching
    .prefetch_cycles (4'h0),
    .read_cycles    (4'h0),

    // Wishbone interface
    .wb_clk_i       (port0_clk_i),
    .wb_rst_i       (port0_rst_i),
    .wbs_stb_i      (port0_stb_i),
    .wbs_cyc_i      (port0_cyc_i),
    .wbs_we_i       (port0_we_i),
    .wbs_ack_o      (port0_ack_o),
    .wbs_dat_o      (port0_dat_o),

    // OpenRAM interface
    .ram_clk        (ram_clk0),     // stretched clock
    .ram_csb        (ram_csb0),     // active low chip select
    .ram_web        (ram_web0),     // active low write control
    .ram_dout       (ram_dout0)
);



// Signals for OpenRAM Port 1 Control block
wire port1_clk_i;
wire port1_rst_i;
wire port1_stb_i;
wire port1_cyc_i;
wire port1_we_i;
wire port1_ack_o;
wire [31:0] port1_dat_o;

// Connect signals going from Wishbone A or B to Port 1 Control block
assign port1_clk_i = writable_port_req ? wb_a_clk_i : wb_b_clk_i;
assign port1_rst_i = writable_port_req ? wb_a_rst_i : wb_b_rst_i;
assign port1_stb_i = writable_port_req ? wbs_a_stb_i : wbs_b_stb_i;
assign port1_cyc_i = writable_port_req ? wbs_a_cyc_i : wbs_b_cyc_i;
assign port1_we_i = writable_port_req ? wbs_a_we_i : wbs_b_we_i;

// Connect signals going directly from Wishbone A or B to OpenRAM port 1 (R)
assign ram_addr1 = writable_port_req ? wbs_a_adr_i[ADDR_WIDTH+1:2] : wbs_b_adr_i[ADDR_WIDTH+1:2];

wb_port_control 
#(
    .READ_ONLY(1),
    .LATENCY_CNTR_WIDTH(4)
) port1_r
(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),	    // User area 1 1.8V supply
    .vssd1 (vssd1),	    // User area 1 digital ground
`endif

    // configuration for clock stretching
    .prefetch_cycles (4'h2),
    .read_cycles    (4'h3),

    // Wishbone interface
    .wb_clk_i       (port1_clk_i),
    .wb_rst_i       (port1_rst_i),
    .wbs_stb_i      (port1_stb_i),
    .wbs_cyc_i      (port1_cyc_i),
    .wbs_we_i       (port1_we_i),
    .wbs_ack_o      (port1_ack_o),
    .wbs_dat_o      (port1_dat_o),

    // OpenRAM interface
    .ram_clk        (ram_clk1),     // stretched clock    
    .ram_csb        (ram_csb1),     // active low chip select
//    .ram_web        ()      // active low write control
    .ram_dout       (ram_dout1)
);
   

// Connect signals going from OpenRAM port 0 or 1 to Wishbone A
assign wbs_a_ack_o = writable_port_req ? port1_ack_o : port0_ack_o;

wire [31:0] doutA;
assign doutA = writable_port_req ? port1_dat_o : port0_dat_o;
assign wbs_a_dat_o = wbs_a_we_i ? wbs_a_dat_i : doutA;

// Connect signals going from OpenRAM port 0 or 1 to Wishbone B
assign wbs_b_ack_o = writable_port_req ? port0_ack_o : port1_ack_o;

wire [31:0] doutB;
assign doutB = writable_port_req ? port0_dat_o : port1_dat_o;
assign wbs_b_dat_o = wbs_b_we_i ? wbs_b_dat_i : doutB;


endmodule	// wb_openram_wrapper

`default_nettype wire
