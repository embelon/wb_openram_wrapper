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
    parameter BASE_ADDR = 32'h3000_0000,
    parameter ADDR_WIDTH = 8
)
(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone port A
    input           wb_clk_i,
    input           wb_rst_i,
    input           wbs_stb_i,
    input           wbs_cyc_i,
    input           wbs_we_i,
    input   [3:0]   wbs_sel_i,
    input   [31:0]  wbs_dat_i,
    input   [31:0]  wbs_adr_i,
    output          wbs_ack_o,
    output  [31:0]  wbs_dat_o,

    // OpenRAM interface - almost dual port: RW + R
    // Port 0: RW
    output                      clk0,       // clock
    output                      csb0,       // active low chip select
    output                      web0,       // active low write control
    output  [3:0]              	wmask0,     // write (byte) mask
    output  [ADDR_WIDTH-1:0]    addr0,
    input   [31:0]              din0,
    output  [31:0]              dout0
/*    
    // Port 1: R
    output                      clk1,       // clock
    output                      csb1,       // active low chip select
    output  [ADDR_WIDTH-1:0]    addr1,  
    output  [31:0]              dout1
*/    
);

parameter ADDR_LO_MASK = (1 << ADDR_WIDTH) - 1;
parameter ADDR_HI_MASK = 32'hffff_ffff - ADDR_LO_MASK;

wire ram_cs;
wire ram_csn;
assign ram_cs = wbs_stb_i && wbs_cyc_i && ((wbs_adr_i & ADDR_HI_MASK) == BASE_ADDR) && !wb_rst_i;
assign ram_csn = !ram_cs;

reg ram_wb_ack;
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        ram_wb_ack <= 0;
    end else begin
        ram_wb_ack <= ram_cs;
    end
end
     
assign clk0 = wb_clk_i;
assign csb0 = ram_csn;
assign web0 = ~wbs_we_i;
assign wmask0 = wbs_sel_i;
assign addr0 = wbs_adr_i[ADDR_WIDTH-1:0];
assign dout0 = wbs_dat_i;

assign wbs_dat_o = din0;
assign wbs_ack_o = ram_wb_ack && ram_cs;

endmodule	// wb_openram_wrapper

`default_nettype wire
