// Instruction Decoder

module instruction_decoder (
    input logic [31:0] instruction,

    // Extracted fields
    output logic [ 6:0] opcode,
    output logic [ 4:0] rd,
    output logic [ 4:0] rs1,
    output logic [ 4:0] rs2,
    output logic [ 2:0] funct3,
    output logic [ 6:0] funct7,
    output logic [63:0] imm,

    // Control signals
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       branch,
    output logic       jump,
    output logic [3:0] alu_op,
    output logic       alu_src,
    output logic [1:0] result_src
);

  assign opcode = instruction[6:0];
  assign rd     = instruction[11:7];
  assign funct3 = instruction[14:12];
  assign rs1    = instruction[19:15];
  assign rs2    = instruction[24:20];
  assign funct7 = instruction[31:25];

  localparam OP_IMM = 7'b0010011;
  localparam OP = 7'b0110011;
  localparam LOAD = 7'b0000011;
  localparam STORE = 7'b0100011;
  localparam BRANCH = 7'b1100011;
  localparam JAL = 7'b1101111;
  localparam JALR = 7'b1100111;
  localparam LUI = 7'b0110111;
  localparam AUIPC = 7'b0010111;

  // Immediate generation
  always_comb begin
    case (opcode)
      OP_IMM, LOAD, JALR: imm = {{52{instruction[31]}}, instruction[31:20]};
      STORE: imm = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};
      BRANCH:
      imm = {
        {51{instruction[31]}},
        instruction[31],
        instruction[7],
        instruction[30:25],
        instruction[11:8],
        1'b0
      };
      LUI, AUIPC: imm = {{32{instruction[31]}}, instruction[31:12], 12'b0};
      JAL:
      imm = {
        {43{instruction[31]}},
        instruction[31],
        instruction[19:12],
        instruction[20],
        instruction[30:21],
        1'b0
      };
      default: imm = 64'b0;
    endcase
  end

  // Control signal generation
  always_comb begin
    reg_write  = 1'b0;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    branch     = 1'b0;
    jump       = 1'b0;
    alu_op     = 4'b0000;
    alu_src    = 1'b0;
    result_src = 2'b00;

    case (opcode)
      OP_IMM: begin
        reg_write  = 1'b1;
        alu_src    = 1'b1;
        result_src = 2'b00;
        case (funct3)
          3'b000:  alu_op = 4'b0000;  // ADDI
          3'b001:  alu_op = 4'b0101;  // SLLI
          3'b010:  alu_op = 4'b1100;  // SLTI
          3'b011:  alu_op = 4'b1101;  // SLTIU 
          3'b100:  alu_op = 4'b0100;  // XORI
          3'b101:  alu_op = (instruction[30]) ? 4'b0111 : 4'b0110;  // SRAI : SRLI
          3'b110:  alu_op = 4'b0011;  // ORI
          3'b111:  alu_op = 4'b0010;  // ANDI
          default: alu_op = 4'b0000;
        endcase
      end

      OP: begin
        reg_write  = 1'b1;
        alu_src    = 1'b0;
        result_src = 2'b00;
        case (funct3)
          3'b000:  alu_op = (funct7[5]) ? 4'b0001 : 4'b0000;  // SUB : ADD
          3'b001:  alu_op = 4'b0101;  // SLL
          3'b010: begin
            if (funct7 == 7'b0010000) alu_op = 4'b1000;  // SH1ADD (Zba)
            else alu_op = 4'b1100;  // SLT 
          end
          3'b011:  alu_op = 4'b1101;  // SLTU 
          3'b100: begin
            if (funct7 == 7'b0010000) alu_op = 4'b1001;  // SH2ADD (Zba)
            else alu_op = 4'b0100;  // XOR
          end
          3'b101:  alu_op = (funct7[5]) ? 4'b0111 : 4'b0110;  // SRA : SRL
          3'b110: begin
            if (funct7 == 7'b0010000) alu_op = 4'b1010;  // SH3ADD (Zba)
            else alu_op = 4'b0011;  // OR
          end
          3'b111:  alu_op = 4'b0010;  // AND
          default: alu_op = 4'b0000;
        endcase
      end

      LOAD: begin
        reg_write  = 1'b1;
        mem_read   = 1'b1;
        alu_src    = 1'b1;
        alu_op     = 4'b0000;  // ADD
        result_src = 2'b01;
      end

      STORE: begin
        mem_write = 1'b1;
        alu_src   = 1'b1;
        alu_op    = 4'b0000; // ADD
      end

      BRANCH: begin
        branch  = 1'b1;
        alu_src = 1'b0;
        // branches use subtraction for comparison
        alu_op  = 4'b0001;
      end

      JAL: begin
        reg_write  = 1'b1;
        jump       = 1'b1;
        result_src = 2'b10;
      end

      JALR: begin
        reg_write  = 1'b1;
        jump       = 1'b1;
        alu_src    = 1'b1;
        alu_op     = 4'b0000;  // ADD (rs1 + imm)
        result_src = 2'b10;
      end

      LUI: begin
        reg_write = 1'b1;
        alu_src   = 1'b1;
        alu_op    = 4'b1111;
        alu_op = 4'b0000;
      end

      AUIPC: begin
        reg_write = 1'b1;
      end

      default: begin
      end
    endcase
  end

endmodule
