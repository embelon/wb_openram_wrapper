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

module wb_port_control 
#(
    parameter READ_ONLY = 1
)
(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone port A
    input           		wb_clk_i,
    input           		wb_rst_i,
    input           		wbs_stb_i,
    input           		wbs_cyc_i,
    input           		wbs_we_i,
    output          		wbs_ack_o,


    // OpenRAM interface: RW
    output          		ram_csb,       // active low chip select
    output          		ram_web        // active low write control
);

wire port_cs;
assign port_cs = wbs_stb_i && wbs_cyc_i && !wb_rst_i;

reg port_cs_r;
reg port_wbs_ack_r;
always @(negedge wb_clk_i) begin
    if (wb_rst_i) begin
        port_cs_r <= 0;
        port_wbs_ack_r <= 0;
    end
    else begin
        port_cs_r <= !port_cs_r && port_cs;
        port_wbs_ack_r <= port_cs_r;
    end
end

wire ignore_write;
assign ignore_write = READ_ONLY && wbs_we_i;

assign ram_csb = !port_cs_r || ignore_write;
assign ram_web = !wbs_we_i || READ_ONLY;

assign wbs_ack_o = port_wbs_ack_r && port_cs;

endmodule	// wb_port_control

`default_nettype wire


