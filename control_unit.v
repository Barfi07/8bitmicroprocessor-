module control_unit(
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  opcode,
	input  wire [2:0]  source1,
	input  wire [2:0]  source2,
	input  wire [2:0]  destination,

    output reg         reg_write,
    output reg  [2:0]  rs1,
    output reg  [2:0]  rs2,
    output reg  [2:0]  rd,

    output reg  [3:0]  alu_op,
    output reg         use_imm,
    output reg         flags_en
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_write <= 0;
        rs1 <= 0; rs2 <= 0; rd <= 0;
        alu_op <= 0;
        use_imm <= 0;
        flags_en <= 0;
    end else begin
        
        reg_write <= 1;
        rs1 <= source1; 
        rs2 <= source2;
        rd  <= destination;

        use_imm <= 0;
        flags_en <= 1;

        case(opcode)

            4'b0000: alu_op <= 4'b0000; 
            4'b0001: alu_op <= 4'b0001; 
            4'b0010: begin alu_op <= 4'b0010; flags_en <= 0; end
            4'b0011: begin alu_op <= 4'b0011; flags_en <= 0; end
            4'b0100: begin alu_op <= 4'b0100; flags_en <= 0; end
            4'b0101: begin alu_op <= 4'b0101; use_imm <= 1; end
            4'b0110: begin alu_op <= 4'b0110; use_imm <= 1; end
            4'b0111: begin alu_op <= 4'b0111; use_imm <= 1; end
            4'b1000: begin alu_op <= 4'b1000; flags_en <= 0; end
            4'b1001: begin alu_op <= 4'b1001; flags_en <= 0; end

            default: begin
                alu_op <= 4'b0000;
                reg_write <= 0;
            end

        endcase
    end
end

endmodule