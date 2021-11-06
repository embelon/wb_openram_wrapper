// SPDX-FileCopyrightText: 2021 Embelon
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

module wb_channel_control 
#(
    parameter BASE_ADDR = 32'h3000_0000,
    parameter ADDR_WIDTH = 8
)
(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Control signal
    input           read_only_i,

    // Wishbone port A
    input           wb_clk_i,
    input           wb_rst_i,
    input           wbs_stb_i,
    input           wbs_cyc_i,
    input           wbs_we_i,
    input   [31:0]  wbs_adr_i,
    output          wbs_ack_o,


    // OpenRAM interface: RW
    output                      ram_csb,       // active low chip select
    output                      ram_web        // active low write control
);

parameter ADDR_LO_MASK = (1 << ADDR_WIDTH) - 1;
parameter ADDR_HI_MASK = 32'hffff_ffff - ADDR_LO_MASK;

wire channel_cs;
assign channel_cs = wbs_stb_i && wbs_cyc_i && ((wbs_adr_i & ADDR_HI_MASK) == BASE_ADDR) && !wb_rst_i;

reg channel_cs_r;
reg channel_wbs_ack_r;
always @(negedge wb_clk_i) begin
    if (wb_rst_i) begin
        channel_cs_r <= 0;
        channel_wbs_ack_r <= 0;
    end
    else begin
        channel_cs_r <= !channel_cs_r && channel_cs;
        channel_wbs_ack_r <= channel_cs_r;
    end
end

wire ignore_write;
assign ignore_write = read_only_i && wbs_we_i;

assign ram_csb = !channel_cs_r || ignore_write;
assign ram_web = !wbs_we_i || read_only_i;

assign wbs_ack_o = channel_wbs_ack_r && channel_cs;

endmodule	// wb_channel_control

`default_nettype wire


