// IF/ID Pipeline Register

module if_id_reg (
    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,

    // Inputs from IF stage
    input logic [63:0] pc_in,
    input logic [31:0] instruction_in,

    // Outputs to ID stage
    output logic [63:0] pc_out,
    output logic [31:0] instruction_out
);

  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      pc_out <= 64'b0;
      instruction_out <= 32'h00000013;  // NOP
    end else if (!stall) begin
      pc_out <= pc_in;
      instruction_out <= instruction_in;
    end
  end

endmodule
