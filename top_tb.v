`timescale 1ns/1ps

module top_tb;

    reg clk;
    reg rst;
    reg [3:0] opcode;
    reg [2:0] source1;
    reg [2:0] source2;
    reg [2:0] destination;

    wire [7:0] result;
    wire Z, C, N, V;

    top_module uut (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .source1(source1),
        .source2(source2),
	    .destination(destination),
        .result(result),
        .Z(Z),
        .C(C),
        .N(N),
        .V(V)
    );

    // 10ns clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        opcode = 4'b0000;
        source1 = 3'b000;
        source2 = 3'b000;
        destination = 3'b000;

        // Apply reset long enough so reg_file initializes
        #50 rst = 0;

        // Initialize registers BEFORE any opcode
        uut.RF.regs[0] = 8'd10;
        uut.RF.regs[1] = 8'd5;
        uut.RF.regs[2] = 8'd6;
        uut.RF.regs[3] = 8'd4;

        #20;

        // Apply operations
        opcode = 4'b0000;
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b0001;  // SUB
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b0010;   // AND
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b0011;   // OR
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b0100;   // XOR
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b0101;   // NOT
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b0110;   // SHL
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b0111;   // SHR
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b1000;   // >
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;
        #20 opcode = 4'b1001;   // ==
        source1 = 3'b000;
        source2 = 3'b010;
        destination = 3'b100;

        #100 $stop;
    end

    initial begin
        $monitor("T=%0dns  OPCODE=%b  A=%d  B=%d  RESULT=%d | Z=%b C=%b N=%b V=%b",
                 $time, opcode, uut.RF.regs[1], uut.RF.regs[2],
                 result, Z, C, N, V);
    end

endmodule

