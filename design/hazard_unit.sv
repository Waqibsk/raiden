// Hazard Detection Unit

module hazard_unit (

    // ID stage
    input logic [4:0] rs1_id,
    input logic [4:0] rs2_id,

    // EX stage
    input logic [4:0] rd_ex,
    input logic       mem_read_ex,
    input logic       reg_write_ex,

    // MEM stage
    input logic [4:0] rd_mem,
    input logic       reg_write_mem,

    // WB stage
    input logic [4:0] rd_wb,
    input logic       reg_write_wb,

    // Branch/Jump control
    input logic branch_taken,
    input logic jump_ex,

    // Outputs
    output logic stall_if,
    output logic stall_id,
    output logic flush_id,
    output logic flush_ex
);

  logic load_use_hazard;
  logic control_hazard;

  // Detect load-use hazard
  always_comb begin
    load_use_hazard = 1'b0;

    if (mem_read_ex && rd_ex != 5'b0) begin
      if ((rd_ex == rs1_id) || (rd_ex == rs2_id)) begin
        load_use_hazard = 1'b1;
      end
    end
  end

  // Detect control hazard (branch or jump)
  assign control_hazard = branch_taken || jump_ex;

  // Generate stall and flush signals
  always_comb begin
    // Default: no stall or flush
    stall_if = 1'b0;
    stall_id = 1'b0;
    flush_id = 1'b0;
    flush_ex = 1'b0;

    // Load-use hazard: stall IF and ID, insert bubble in EX
    if (load_use_hazard) begin
      stall_if = 1'b1;
      stall_id = 1'b1;
      flush_ex = 1'b1; 
    end

    // Control hazard: when branch/jump is taken, allow the target instruction to proceed
    // clear any fetched instruction before branch resolution
    if (control_hazard) begin
      flush_id = 1'b1;
    end
  end

endmodule
