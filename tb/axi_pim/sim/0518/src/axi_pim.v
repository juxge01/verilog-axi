/*

Copyright (c) 2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 RAM
 */
module axi_pim #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 8,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8), //4
    // Width of ID signal
    parameter ID_WIDTH = 8,
    // Extra pipeline register on output
    parameter PIPELINE_OUTPUT = 0,
    parameter PWIDTH = 32
)
(
    input  wire                   clk,
    input  wire                   rst,

    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awlock,
    input  wire [3:0]             s_axi_awcache,
    input  wire [2:0]             s_axi_awprot,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,
    output wire [ID_WIDTH-1:0]    s_axi_bid,
    output wire [1:0]             s_axi_bresp,
    output wire                   s_axi_bvalid,
    input  wire                   s_axi_bready,
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arlock,
    input  wire [3:0]             s_axi_arcache,
    input  wire [2:0]             s_axi_arprot,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,
    output wire [ID_WIDTH-1:0]    s_axi_rid,
    output wire [DATA_WIDTH-1:0]  s_axi_rdata,
    output wire [1:0]             s_axi_rresp,
    output wire                   s_axi_rlast,
    output wire                   s_axi_rvalid,
    input  wire                   s_axi_rready,

    output wire [PWIDTH-1:0] q,
    output wire [DATA_WIDTH-1:0] mac_out
);

parameter VALID_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
parameter WORD_WIDTH = STRB_WIDTH;
parameter WORD_SIZE = DATA_WIDTH/WORD_WIDTH;

// bus width assertions
initial begin
    if (WORD_SIZE * STRB_WIDTH != DATA_WIDTH) begin
        $error("Error: AXI data width not evenly divisble (instance %m)");
        $finish;
    end

    if (2**$clog2(WORD_WIDTH) != WORD_WIDTH) begin
        $error("Error: AXI word width must be even power of two (instance %m)");
        $finish;
    end
end

// 내부 신호 선언
reg [ADDR_WIDTH-1:0] write_addr_reg, write_addr_next;
reg [7:0] write_len_reg, write_len_next;
reg [2:0] write_size_reg, write_size_next;
reg [1:0] write_burst_reg, write_burst_next;
reg write_valid_reg, write_valid_next;
reg [DATA_WIDTH-1:0] write_data_reg, write_data_next;
reg [STRB_WIDTH-1:0] write_strb_reg, write_strb_next;

reg [ADDR_WIDTH-1:0] read_addr_reg, read_addr_next;
reg [7:0] read_len_reg, read_len_next;
reg [2:0] read_size_reg, read_size_next;
reg [1:0] read_burst_reg, read_burst_next;
reg read_valid_reg, read_valid_next;

wire [VALID_ADDR_WIDTH-1:0] write_addr_valid = write_addr_reg >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
wire [VALID_ADDR_WIDTH-1:0] read_addr_valid = read_addr_reg >> (ADDR_WIDTH - VALID_ADDR_WIDTH);

assign s_axi_awready = !write_valid_reg;
assign s_axi_wready = write_valid_reg && (write_len_reg > 0);
assign s_axi_arready = !read_valid_reg;

assign s_axi_bid = s_axi_awid;
assign s_axi_bresp = 2'b00;
assign s_axi_bvalid = write_valid_reg && (write_len_reg == 0);

assign s_axi_rid = s_axi_arid;
assign s_axi_rdata = q;
assign s_axi_rresp = 2'b00;
assign s_axi_rlast = (read_len_reg == 0);
assign s_axi_rvalid = read_valid_reg && (read_len_reg > 0);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        write_valid_reg <= 1'b0;
        write_len_reg <= 0;
        read_valid_reg <= 1'b0;
        read_len_reg <= 0;
    end 
	else begin
        if (s_axi_awvalid && s_axi_awready) begin
            write_valid_reg <= 1'b1;
            write_addr_reg <= s_axi_awaddr;
            write_len_reg <= s_axi_awlen + 1;
            write_size_reg <= s_axi_awsize;
            write_burst_reg <= s_axi_awburst;
        end

        if (s_axi_wvalid && s_axi_wready) begin
            write_data_reg <= s_axi_wdata;
            write_strb_reg <= s_axi_wstrb;
            if (s_axi_wlast) begin
                write_len_reg <= 0;
                write_valid_reg <= 1'b0;
            end 
			else begin
                write_len_reg <= write_len_reg - 1;
                write_addr_reg <= write_addr_reg + (1 << write_size_reg);
            end
        end

        if (s_axi_arvalid && s_axi_arready) begin
            read_valid_reg <= 1'b1;
            read_addr_reg <= s_axi_araddr;
            read_len_reg <= s_axi_arlen + 1;
            read_size_reg <= s_axi_arsize;
            read_burst_reg <= s_axi_arburst;
        end

        if (s_axi_rready && s_axi_rvalid) begin
            if (read_len_reg > 0) begin
                read_len_reg <= read_len_reg - 1;
                read_addr_reg <= read_addr_reg + (1 << read_size_reg);
            end 
			else begin
                read_valid_reg <= 1'b0;
            end
        end
    end
end

reg [255:0] pim_rwl;

integer i;
always @(posedge clk) begin       
	if (!rst) begin
    	pim_rwl <= 256'd0;  // Clear all on reset
    end
    else begin
    	for (i = 0; i < 256; i = i+1) begin
        	pim_rwl[i] <= $random % 2;  // Each bit randomly set to 0 or 1
        end
    end
end

PIM_MODEL #(
    .PIM_ADDR_BEGIN('h000),
    .DWIDTH(DATA_WIDTH),
    .AWIDTH(ADDR_WIDTH),
    .PWIDTH(PWIDTH),
    .PDEPTH(256)
) pim_inst (
    .q(q),
    .mac_out(mac_out),
    .d(write_data_reg),
    .addr(write_valid_reg ? write_addr_valid : read_addr_valid),
    .rwl(pim_rwl),
    .w_en(write_valid_reg),
    .p_en(!write_valid_reg && !read_valid_reg),
    .clk(clk)
);

endmodule

`resetall
