// MEM/WB Pipeline Register

module mem_wb_reg (
    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,

    // Control signals
    input logic       reg_write_in,
    input logic [1:0] result_src_in,

    // Data
    input logic [63:0] pc_plus_4_in,
    input logic [63:0] alu_result_in,
    input logic [63:0] mem_data_in,
    input logic [ 4:0] rd_in,

    // Outputs to WB stage
    output logic       reg_write_out,
    output logic [1:0] result_src_out,

    output logic [63:0] pc_plus_4_out,
    output logic [63:0] alu_result_out,
    output logic [63:0] mem_data_out,
    output logic [ 4:0] rd_out
);

  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      reg_write_out <= 1'b0;
      result_src_out <= 2'b0;
      pc_plus_4_out <= 64'b0;
      alu_result_out <= 64'b0;
      mem_data_out <= 64'b0;
      rd_out <= 5'b0;
    end else if (!stall) begin
      reg_write_out <= reg_write_in;
      result_src_out <= result_src_in;
      pc_plus_4_out <= pc_plus_4_in;
      alu_result_out <= alu_result_in;
      mem_data_out <= mem_data_in;
      rd_out <= rd_in;
    end
  end

endmodule
