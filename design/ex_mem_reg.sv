// EX/MEM Pipeline Register

module ex_mem_reg (
    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,

    // Control signals
    input logic       reg_write_in,
    input logic       mem_read_in,
    input logic       mem_write_in,
    input logic [1:0] result_src_in,

    // Data
    input logic [63:0] pc_plus_4_in,
    input logic [63:0] alu_result_in,
    input logic [63:0] rs2_data_in,
    input logic [ 4:0] rd_in,
    input logic [ 2:0] funct3_in,

    // Outputs to MEM stage
    output logic       reg_write_out,
    output logic       mem_read_out,
    output logic       mem_write_out,
    output logic [1:0] result_src_out,

    output logic [63:0] pc_plus_4_out,
    output logic [63:0] alu_result_out,
    output logic [63:0] rs2_data_out,
    output logic [ 4:0] rd_out,
    output logic [ 2:0] funct3_out
);

  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      reg_write_out <= 1'b0;
      mem_read_out <= 1'b0;
      mem_write_out <= 1'b0;
      result_src_out <= 2'b0;
      pc_plus_4_out <= 64'b0;
      alu_result_out <= 64'b0;
      rs2_data_out <= 64'b0;
      rd_out <= 5'b0;
      funct3_out <= 3'b0;
    end else if (!stall) begin
      reg_write_out <= reg_write_in;
      mem_read_out <= mem_read_in;
      mem_write_out <= mem_write_in;
      result_src_out <= result_src_in;
      pc_plus_4_out <= pc_plus_4_in;
      alu_result_out <= alu_result_in;
      rs2_data_out <= rs2_data_in;
      rd_out <= rd_in;
      funct3_out <= funct3_in;
    end
  end

endmodule
