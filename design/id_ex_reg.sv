// ID/EX Pipeline Register

module id_ex_reg (

    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,

    // Control signals
    input logic       reg_write_in,
    input logic       mem_read_in,
    input logic       mem_write_in,
    input logic       branch_in,
    input logic       jump_in,
    input logic [3:0] alu_op_in,
    input logic       alu_src_in,
    input logic [1:0] result_src_in,

    // Data
    input logic [63:0] pc_in,
    input logic [63:0] rs1_data_in,
    input logic [63:0] rs2_data_in,
    input logic [63:0] imm_in,
    input logic [ 4:0] rd_in,
    input logic [ 4:0] rs1_in,
    input logic [ 4:0] rs2_in,
    input logic [ 2:0] funct3_in,
    input logic [ 6:0] opcode_in,

    // Outputs to EX stage
    output logic       reg_write_out,
    output logic       mem_read_out,
    output logic       mem_write_out,
    output logic       branch_out,
    output logic       jump_out,
    output logic [3:0] alu_op_out,
    output logic       alu_src_out,
    output logic [1:0] result_src_out,

    output logic [63:0] pc_out,
    output logic [63:0] rs1_data_out,
    output logic [63:0] rs2_data_out,
    output logic [63:0] imm_out,
    output logic [ 4:0] rd_out,
    output logic [ 4:0] rs1_out,
    output logic [ 4:0] rs2_out,
    output logic [ 2:0] funct3_out,
    output logic [ 6:0] opcode_out
);

  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      // Control signals
      reg_write_out <= 1'b0;
      mem_read_out <= 1'b0;
      mem_write_out <= 1'b0;
      branch_out <= 1'b0;
      jump_out <= 1'b0;
      alu_op_out <= 4'b0;
      alu_src_out <= 1'b0;
      result_src_out <= 2'b0;

      // Data
      pc_out <= 64'b0;
      rs1_data_out <= 64'b0;
      rs2_data_out <= 64'b0;
      imm_out <= 64'b0;
      rd_out <= 5'b0;
      rs1_out <= 5'b0;
      rs2_out <= 5'b0;
      funct3_out <= 3'b0;
      opcode_out <= 7'b0;
    end else if (!stall) begin
      // Control signals
      reg_write_out <= reg_write_in;
      mem_read_out <= mem_read_in;
      mem_write_out <= mem_write_in;
      branch_out <= branch_in;
      jump_out <= jump_in;
      alu_op_out <= alu_op_in;
      alu_src_out <= alu_src_in;
      result_src_out <= result_src_in;

      // Data
      pc_out <= pc_in;
      rs1_data_out <= rs1_data_in;
      rs2_data_out <= rs2_data_in;
      imm_out <= imm_in;
      rd_out <= rd_in;
      rs1_out <= rs1_in;
      rs2_out <= rs2_in;
      funct3_out <= funct3_in;
      opcode_out <= opcode_in;
    end
  end

endmodule
