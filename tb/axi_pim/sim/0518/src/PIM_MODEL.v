module PIM_MODEL#(
    parameter PIM_ADDR_BEGIN = 'h000,
    parameter DWIDTH = 32,   // DATA WIDTH
    parameter AWIDTH = 8,   // ADDRESS WIDTH
    parameter PWIDTH = 32,   // PIM WIDTH
    parameter PDEPTH = (1 << AWIDTH) // PIM DEPTH
)(q, mac_out, d, addr, rwl, w_en, p_en, clk);

    output [PWIDTH-1:0] q;
    output [DWIDTH-1:0] mac_out;
    input [PWIDTH-1:0] d;
    input [AWIDTH-1:0] addr; // Memory Address
    input [PDEPTH-1:0] rwl; // PIM input line
    input w_en;   // Memory Write Enable / Read Disable
    input p_en; // Processing Enable
    input clk;

    reg [PWIDTH-1:0] mem [PIM_ADDR_BEGIN:PIM_ADDR_BEGIN+PDEPTH-1];
    reg [DWIDTH-1:0] adc_out [0:PWIDTH-1];
    reg [5-1:0]      shift_cnt;
    reg [DWIDTH-1:0] acc_result [0:PWIDTH-1];
    reg [DWIDTH-1:0] sum_acc_result;
    reg [DWIDTH-1:0] mac_out_reg;
    reg [PWIDTH-1:0] q_reg;

    integer i;
    integer j;
    always@(posedge clk) begin
        if(!p_en) begin // Processing Disabled -> Memory operation
            if(w_en) begin // Memory Write Enable
                mem[addr] <= d;
            end
            else begin // Memory Read Enable
                q_reg <= mem[addr];
            end
            // ** initialize accumulation **
            shift_cnt <= 0;
            for(i = 0; i < PWIDTH; i=i+1) begin
                acc_result[i] <= 0;
            end
        end 
        else begin // Processing Enabled -> MAC operation
            for(i = 0; i < PWIDTH; i=i+1) begin
                acc_result[i] <= (shift_cnt == 0) ? adc_out[i] : acc_result[i] + (adc_out[i] << shift_cnt);
            end
            shift_cnt <= shift_cnt + 1;
        end
        mac_out_reg <= sum_acc_result;
    end
    assign q = q_reg;
    assign mac_out = mac_out_reg;

    always@(rwl) begin // ADC Output is modeled
        for(i = 0; i < PWIDTH; i=i+1) begin
            adc_out[i] = 0;
            for(j = 0; j < PDEPTH; j=j+1) begin
                adc_out[i] = adc_out[i] + (mem[PIM_ADDR_BEGIN+j][i] & rwl[j]);
            end
        end
    end

    always@(*) begin
        sum_acc_result = 0;
        for(i = 0; i < PWIDTH; i=i+1) begin
            sum_acc_result = sum_acc_result + (acc_result[i] << i);
        end
    end

    wire [32:0] acc_result_0 = acc_result[0];
    wire [32:0] acc_result_1 = acc_result[1];
    wire [32:0] acc_result_2 = acc_result[2];
    wire [32:0] acc_result_3 = acc_result[3];
    wire [32:0] acc_result_4 = acc_result[4];
    wire [32:0] acc_result_5 = acc_result[5];

endmodule