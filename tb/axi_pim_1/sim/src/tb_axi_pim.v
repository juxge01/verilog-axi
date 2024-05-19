`timescale 1ns / 1ps

module tb_axi_pim();

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 8;
    parameter PWIDTH = 32;
    parameter STRB_WIDTH = DATA_WIDTH / 8;
    parameter ID_WIDTH = 8;
    parameter BURST_LENGTH = 4; 
    parameter CLOCK_PERIOD = 10; 

    // Clock and reset
    reg clk = 0;
    reg rst = 1;

    // AXI signals
    reg [ID_WIDTH-1:0] s_axi_awid;
    reg [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg [7:0] s_axi_awlen;
    reg [2:0] s_axi_awsize;
    reg [1:0] s_axi_awburst;
    reg s_axi_awlock;
    reg [3:0] s_axi_awcache;
    reg [2:0] s_axi_awprot;
    reg s_axi_awvalid;
    wire s_axi_awready;
    reg [DATA_WIDTH-1:0] s_axi_wdata;
    reg [STRB_WIDTH-1:0] s_axi_wstrb;
    reg s_axi_wlast;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire [ID_WIDTH-1:0] s_axi_bid;
    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_bready;
    reg [ID_WIDTH-1:0] s_axi_arid;
    reg [ADDR_WIDTH-1:0] s_axi_araddr;
    reg [7:0] s_axi_arlen;
    reg [2:0] s_axi_arsize;
    reg [1:0] s_axi_arburst;
    reg s_axi_arlock;
    reg [3:0] s_axi_arcache;
    reg [2:0] s_axi_arprot;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire [ID_WIDTH-1:0] s_axi_rid;
    wire [DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rlast;
    wire s_axi_rvalid;
    reg s_axi_rready;
    wire [PWIDTH-1:0] q;
    wire [DATA_WIDTH-1:0] mac_out;

    // Instantiate the Unit Under Test (UUT)
    axi_pim #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .PIPELINE_OUTPUT(0),
	.PWIDTH(PWIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .s_axi_awid(s_axi_awid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bid(s_axi_bid),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rid(s_axi_rid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rlast(s_axi_rlast),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
	.q(q),
	.mac_out(mac_out)
    );

    // Clock generation
    always #(CLOCK_PERIOD / 2) clk = ~clk;

    // Reset generation
    initial begin
        // Initialize Inputs
        s_axi_awid = 0;
        s_axi_awaddr = 0;
        s_axi_awlen = BURST_LENGTH - 1;
        s_axi_awsize = 2; // Corresponding to DATA_WIDTH of 32 bits
        s_axi_awburst = 2'b01; // INCR type
        s_axi_awlock = 0;
        s_axi_awcache = 0;
        s_axi_awprot = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = {STRB_WIDTH{1'b1}}; // All bytes are valid
        s_axi_wlast = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_arid = 0;
        s_axi_araddr = 0;
        s_axi_arlen = BURST_LENGTH - 1;
        s_axi_arsize = 2; // Corresponding to DATA_WIDTH of 32 bits
        s_axi_arburst = 2'b01; // INCR type
        s_axi_arlock = 0;
        s_axi_arcache = 0;
        s_axi_arprot = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        // Wait 100 ns for global reset to finish
        #100;
        rst = 0;

        // Add stimulus here
        test_burst_write_and_read();
	$display("mac_out : %h", mac_out);

        // Complete
        $finish;
    end

    // Test functions
    task test_burst_write_and_read;
        integer i;
        begin
            // Burst Write
            @(posedge clk);
            s_axi_awid = 1;
            s_axi_awaddr = 32'h0000_0000;
            s_axi_awlen = BURST_LENGTH - 1; // 4-beat burst
            s_axi_awsize = $clog2(DATA_WIDTH/8);
            s_axi_awburst = 2'b01; // INCR
            s_axi_awvalid = 1;
            @(posedge clk);
            s_axi_awvalid = 0;

            for (i = 0; i < BURST_LENGTH; i = i + 1) begin
                @(posedge clk);
                s_axi_wdata = 32'hDEAD_BEEF + i;
                s_axi_wstrb = {STRB_WIDTH{1'b1}};
                s_axi_wvalid = 1;
                s_axi_wlast = (i == BURST_LENGTH - 1) ? 1'b1 : 1'b0;
                @(posedge clk);
            end
            s_axi_wvalid = 0;
            s_axi_wlast = 0;

            s_axi_bready = 1;
            @(posedge clk);
            s_axi_bready = 0;

            // Burst Read
            @(posedge clk);
            s_axi_arid = 1;
            s_axi_araddr = 32'h0000_0000;
            s_axi_arlen = BURST_LENGTH - 1; // 4-beat burst
            s_axi_arsize = $clog2(DATA_WIDTH/8);
            s_axi_arburst = 2'b01; // INCR
            s_axi_arvalid = 1;
            @(posedge clk);
            s_axi_arvalid = 0;

            for (i = 0; i < BURST_LENGTH; i = i + 1) begin
                @(posedge clk);
                s_axi_rready = 1;
                @(posedge clk);
                // Check received data
                if (s_axi_rdata != 32'hDEAD_BEEF + i) begin
                    $display("Mismatch in data received: expected %h, got %h", 32'hDEAD_BEEF + i, s_axi_rdata);
                end
                if (s_axi_rlast && (i != BURST_LENGTH - 1)) begin
                    $display("Early rlast at index %d", i);
                end
                if (i == BURST_LENGTH - 1 && !s_axi_rlast) begin
                    $display("Missing rlast at the end of the burst");
                end
            end
            s_axi_rready = 0;
        end
    endtask

endmodule
