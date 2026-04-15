module reg_file(
    input clk,
    input rst,
    input we,
    input [2:0] r_addr1,
    input [2:0] r_addr2,
    input [2:0] w_addr,
    input [7:0] w_data,
    output [7:0] r_data1,
    output [7:0] r_data2
);

reg [7:0] regs[0:15];

assign r_data1 = regs[r_addr1];
assign r_data2 = regs[r_addr2];

integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < 16; i = i + 1)
            regs[i] <= 8'd0;
    end 
    else if (we) begin
        regs[w_addr] <= w_data;
    end
end

endmodule

