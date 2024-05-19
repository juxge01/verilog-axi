module testbench;
    reg clk;
    reg rst;
    reg [7:0] awid;
    reg [15:0] awaddr;
    reg [7:0] awlen;
    reg [2:0] awsize;
    reg [1:0] awburst;
    reg awvalid;
    wire awready;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg wlast;
    reg wvalid;
    wire wready;
    wire [7:0] bid;
    wire [1:0] bresp;
    wire bvalid;
    reg bready;
    reg [7:0] arid;
    reg [15:0] araddr;
    reg [7:0] arlen;
    reg [2:0] arsize;
    reg [1:0] arburst;
    reg arvalid;
    wire arready;
    wire [7:0] rid;
    wire [31:0] rdata_axi_ram;
    wire [31:0] rdata_axi_pim;
    wire [1:0] rresp;
    wire rlast;
    wire rvalid;
    reg rready;
    wire [31:0] q;
    wire [31:0] mac_out;

    // AXI4 RAM 인스턴스
    axi_ram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(16),
        .STRB_WIDTH(4),
        .ID_WIDTH(8),
        .PIPELINE_OUTPUT(0)
    ) dut1 (
        .clk(clk),
        .rst(rst),
        .s_axi_awid(awid),
        .s_axi_awaddr(awaddr),
        .s_axi_awlen(awlen),
        .s_axi_awsize(awsize),
        .s_axi_awburst(awburst),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wlast(wlast),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),
        .s_axi_bid(bid),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),
        .s_axi_arid(arid),
        .s_axi_araddr(araddr),
        .s_axi_arlen(arlen),
        .s_axi_arsize(arsize),
        .s_axi_arburst(arburst),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_rid(rid),
        .s_axi_rdata(rdata_axi_ram),
        .s_axi_rresp(rresp),
        .s_axi_rlast(rlast),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready)
    );

    // AXI4 PIM 인스턴스
    axi_pim #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(8),
        .STRB_WIDTH(4),
        .ID_WIDTH(8),
        .PIPELINE_OUTPUT(0),
        .PWIDTH(32)
    ) dut2 (
        .clk(clk),
        .rst(rst),
        .s_axi_awid(awid),
        .s_axi_awaddr(awaddr[7:0]),
        .s_axi_awlen(awlen),
        .s_axi_awsize(awsize),
        .s_axi_awburst(awburst),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wlast(wlast),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),
        .s_axi_bid(bid),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),
        .s_axi_arid(arid),
        .s_axi_araddr(araddr[7:0]),
        .s_axi_arlen(arlen),
        .s_axi_arsize(arsize),
        .s_axi_arburst(arburst),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_rid(rid),
        .s_axi_rdata(rdata_axi_pim),
        .s_axi_rresp(rresp),
        .s_axi_rlast(rlast),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),
        .mac_out(mac_out)
    );

	integer i;

    initial begin
		// 초기 설정
        clk = 0;
        rst = 1;
        awid = 0;
        awaddr = 0;
        awlen = 0;
        awsize = 3'd2; // 4 bytes
        awburst = 2'd0;
        awvalid = 0;
        wdata = 0;
        wstrb = 4'b1111;
        wlast = 1;
        wvalid = 0;
        bready = 1;
        arid = 0;
        araddr = 0;
        arlen = 0;
        arsize = 3'd2; // 4 bytes
        arburst = 2'd0;
        arvalid = 0;
        rready = 1;

        // 리셋 해제
        #5 rst = 0;

        for (i = 0; i < 50; i = i + 1) begin
            // 랜덤 쓰기 동작
            awaddr = $random % 65536;  // 16-bit 주소
            wdata = $random;
            #10 awvalid = 1;
            #10 wvalid = 1;
            #10 awvalid = 0;
            #10 wvalid = 0;

            // 랜덤 읽기 동작
            araddr = awaddr;
            #10 arvalid = 1;
            #10 arvalid = 0;

            // 기다림
            #20;

            // 출력 비교

            if (rdata_axi_ram == rdata_axi_pim) begin
                $display("[%d] %t [[Equal]] %h = %h", i, $time, rdata_axi_ram, rdata_axi_pim);
            end else begin
                $display("[%d] %t XXXXX NOT Equal XXXXX %h = %h", i, $time, rdata_axi_ram, rdata_axi_pim);
            end
        end

        // 시뮬레이션 종료
        #100 $finish;
    end

    // 시계 생성
    always #5 clk = ~clk;

    /* 모니터링
    initial begin
        $monitor("At time %t, rdata (axi_ram) = %h, rdata (axi_pim) = %h", $time, rdata_axi_ram, rdata_axi_pim);
    end
	*/
endmodule

