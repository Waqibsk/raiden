// Forwarding Unit

module forwarding_unit (
    // ID/EX stage
    input logic [4:0] rs1_ex,
    input logic [4:0] rs2_ex,

    // EX/MEM stage 
    input logic [4:0] rd_mem,
    input logic       reg_write_mem,

    // MEM/WB stage
    input logic [4:0] rd_wb,
    input logic       reg_write_wb,

    // Forwarding control outputs
    output logic [1:0] forward_a,  // For rs1
    output logic [1:0] forward_b   // For rs2
);

  // Forward codes:
  // 00 = No forwarding (use register file)
  // 01 = Forward from EX/MEM stage (most recent ALU result)
  // 10 = Forward from MEM/WB stage (data from memory or older ALU result)

  always_comb begin
    // Default: no forwarding
    forward_a = 2'b00;
    forward_b = 2'b00;

    // Forward to rs1 
    if (reg_write_mem && rd_mem != 5'b0 && rd_mem == rs1_ex) begin
      forward_a = 2'b01;  // Forward from EX/MEM stage
    end else if (reg_write_wb && rd_wb != 5'b0 && rd_wb == rs1_ex) begin
      forward_a = 2'b10;  // Forward from MEM/WB stage
    end

    // Forward to rs2
    if (reg_write_mem && rd_mem != 5'b0 && rd_mem == rs2_ex) begin
      forward_b = 2'b01;  // Forward from EX/MEM stage
    end else if (reg_write_wb && rd_wb != 5'b0 && rd_wb == rs2_ex) begin
      forward_b = 2'b10;  // Forward from MEM/WB stage
    end
  end

endmodule
