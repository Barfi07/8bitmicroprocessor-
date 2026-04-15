module top_module(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] opcode,
	input  wire [2:0]  source1,
	input  wire [2:0]  source2,
	input  wire [2:0]  destination,

    output wire [7:0] result,
    output wire Z, C, N, V
);

    wire reg_write;
    wire [3:0] rs1, rs2, rd;
    wire use_imm, flags_en;
    wire [3:0] alu_op;

    wire [7:0] r_data1;
    wire [7:0] r_data2;

    wire [7:0] alu_A = r_data1;
    wire [7:0] alu_B = use_imm ? 8'd1 : r_data2;

    control_unit CU (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
		.source1(source1),
		.source2(source2),
		.destination(destination),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_op(alu_op),
        .use_imm(use_imm),
        .flags_en(flags_en)
    );

    reg_file RF (
        .clk(clk),
        .rst(rst),
        .we(reg_write),
        .r_addr1(rs1),
        .r_addr2(rs2),
        .w_addr(rd),
        .w_data(result),
        .r_data1(r_data1),
        .r_data2(r_data2)
    );

    alu ALU_inst (
        .A(alu_A),
        .B(alu_B),
        .alu_op(alu_op),
        .result(result),
        .Z(Z),
        .C(C),
        .N(N),
        .V(V)
    );

endmodule