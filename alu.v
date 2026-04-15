module alu (
    input  [7:0] A,         
    input  [7:0] B,         
    input  [3:0] alu_op,    
    output reg [7:0] result,
    output reg Z,           
    output reg C,           
    output reg N,           
    output reg V            
);

    reg [8:0] temp; // 9-bit temp

    always @(*) begin
        
        result = 8'b0;
        C = 0;
        V = 0;

        case (alu_op)

            4'b0000: begin  // ADD
                temp = A + B;
                result = temp[7:0];
                C = temp[8];
                V = (A[7] == B[7]) && (result[7] != A[7]);
            end

            4'b0001: begin  // SUB
                temp = A - B;
                result = temp[7:0];
                C = ~temp[8]; 
                V = (A[7] != B[7]) && (result[7] != A[7]);
            end

            4'b0010: result = A & B;       
            4'b0011: result = A | B;       
            4'b0100: result = A ^ B;       
            4'b0101: result = ~A;          

            4'b0110: begin                
                C = A[7];
                result = A << 1;
            end

            4'b0111: begin                 
                C = A[0];
                result = A >> 1;
            end

            4'b1000: result = (A > B) ? 8'd1 : 8'd0;
            4'b1001: result = (A == B) ? 8'd1 : 8'd0;

            default: result = 8'b0;

        endcase

        Z = (result == 8'd0);
        N = result[7];
    end

endmodule
