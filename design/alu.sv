// ALU 

module alu (
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  logic [ 3:0] alu_op,  
    output logic [63:0] result
);

  // ALU Operation Codes
  localparam ALU_ADD = 4'b0000;
  localparam ALU_SUB = 4'b0001;
  localparam ALU_AND = 4'b0010;
  localparam ALU_OR = 4'b0011;
  localparam ALU_XOR = 4'b0100;
  localparam ALU_SLL = 4'b0101;  // Shift left logical
  localparam ALU_SRL = 4'b0110;  // Shift right logical
  localparam ALU_SRA = 4'b0111;  // Shift right arithmetic
  localparam ALU_SH1ADD = 4'b1000;  // Zba: (a << 1) + b
  localparam ALU_SH2ADD = 4'b1001;  // Zba: (a << 2) + b
  localparam ALU_SH3ADD = 4'b1010;  // Zba: (a << 3) + b

  always_comb begin
    case (alu_op)
      ALU_ADD:    result = a + b;
      ALU_SUB:    result = a - b;
      ALU_AND:    result = a & b;
      ALU_OR:     result = a | b;
      ALU_XOR:    result = a ^ b;
      ALU_SLL:    result = a << b[5:0];
      ALU_SRL:    result = a >> b[5:0];
      ALU_SRA:    result = $signed(a) >>> b[5:0];  // Arithmetic shift
      ALU_SH1ADD: result = (a << 1) + b;  // Zba extension
      ALU_SH2ADD: result = (a << 2) + b;  // Zba extension
      ALU_SH3ADD: result = (a << 3) + b;  // Zba extension
      default:    result = 64'b0;
    endcase
  end

endmodule
