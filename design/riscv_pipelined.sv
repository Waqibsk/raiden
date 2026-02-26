// 5-Stage Pipelined RISC-V Processor
// Stages: IF -> ID -> EX -> MEM -> WB

module riscv_pipelined (
    input logic clk,
    input logic rst
);


  // IF Stage
  logic [63:0] pc_if;
  logic [63:0] pc_next;
  logic [31:0] instruction_if;
  logic [63:0] pc_plus_4_if;

  // IF/ID Pipeline Register
  logic [63:0] pc_id;
  logic [31:0] instruction_id;

  // ID Stage
  logic [ 6:0] opcode_id;
  logic [4:0] rd_id, rs1_id, rs2_id;
  logic [ 2:0] funct3_id;
  logic [ 6:0] funct7_id;
  logic [63:0] imm_id;
  logic reg_write_id, mem_read_id, mem_write_id;
  logic branch_id, jump_id;
  logic [3:0] alu_op_id;
  logic       alu_src_id;
  logic [1:0] result_src_id;
  logic [63:0] rs1_data_id, rs2_data_id;

  // ID/EX Pipeline Register
  logic reg_write_ex, mem_read_ex, mem_write_ex;
  logic branch_ex, jump_ex;
  logic [ 3:0] alu_op_ex;
  logic        alu_src_ex;
  logic [ 1:0] result_src_ex;
  logic [63:0] pc_ex;
  logic [63:0] rs1_data_ex, rs2_data_ex;
  logic [63:0] imm_ex;
  logic [4:0] rd_ex, rs1_ex, rs2_ex;
  logic [2:0] funct3_ex;
  logic [6:0] opcode_ex;

  // EX Stage
  logic [63:0] alu_in1, alu_in2;
  logic [63:0] alu_result_ex;
  logic        alu_zero;
  logic        branch_taken;
  logic [63:0] pc_branch_target;
  logic [63:0] pc_plus_4_ex;
  logic [63:0] alu_forward_a, alu_forward_b;
  logic [1:0] forward_a, forward_b;

  // EX/MEM Pipeline Register
  logic reg_write_mem, mem_read_mem, mem_write_mem;
  logic [ 1:0] result_src_mem;
  logic [63:0] pc_plus_4_mem;
  logic [63:0] alu_result_mem;
  logic [63:0] rs2_data_mem;
  logic [ 4:0] rd_mem;
  logic [ 2:0] funct3_mem;

  // MEM Stage
  logic [63:0] mem_read_data;

  // MEM/WB Pipeline Register
  logic        reg_write_wb;
  logic [ 1:0] result_src_wb;
  logic [63:0] pc_plus_4_wb;
  logic [63:0] alu_result_wb;
  logic [63:0] mem_data_wb;
  logic [ 4:0] rd_wb;

  // WB Stage
  logic [63:0] rd_data_wb;

  // Hazard signals
  logic stall_if, stall_id, flush_id, flush_ex;


  // ========== IF Stage ==========

  assign pc_plus_4_if = pc_if + 4;

  // Jump target computed in ID stage
  logic [63:0] pc_jump_target_id;
  assign pc_jump_target_id = pc_id + imm_id;

  // PC Update logic - detect jumps in ID stage to avoid delay
  always_comb begin
    if (branch_taken) begin
      pc_next = pc_branch_target;
    end else if (jump_id) begin
      // Handle JAL in ID stage (branches in EX stage)
      pc_next = pc_jump_target_id;
    end else if (jump_ex) begin
      // Handle JALR in EX stage (needs rs1 value)
      if (opcode_ex == 7'b1100111) begin  // JALR
        pc_next = (alu_result_ex & ~64'b1);
      end else begin  // JAL (shouldn't reach here, but kept for safety)
        pc_next = pc_ex + imm_ex;
      end
    end else begin
      pc_next = pc_plus_4_if;
    end
  end

  // Program Counter
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pc_if <= 64'h0000_0000;
    end else if (!stall_if) begin
      pc_if <= pc_next;
    end
  end

  // Instruction Memory
  instruction_memory #(
      .MEM_SIZE(1024)
  ) imem (
      .pc(pc_if),
      .instruction(instruction_if)
  );

  // Flush IF/ID when jump detected in ID stage to prevent wrong instruction from executing
  logic flush_id_jump;
  assign flush_id_jump = jump_id;  // Flush the IF/ID register when JAL is detected

  // IF/ID Pipeline Register
  if_id_reg if_id (
      .clk(clk),
      .rst(rst),
      .stall(stall_id),
      .flush(flush_id | flush_id_jump),  // Flush on hazard OR jump detection
      .pc_in(pc_if),
      .instruction_in(instruction_if),
      .pc_out(pc_id),
      .instruction_out(instruction_id)
  );


  // ========== ID Stage ==========

  // Instruction Decoder
  instruction_decoder decoder (
      .instruction(instruction_id),
      .opcode(opcode_id),
      .rd(rd_id),
      .rs1(rs1_id),
      .rs2(rs2_id),
      .funct3(funct3_id),
      .funct7(funct7_id),
      .imm(imm_id),
      .reg_write(reg_write_id),
      .mem_read(mem_read_id),
      .mem_write(mem_write_id),
      .branch(branch_id),
      .jump(jump_id),
      .alu_op(alu_op_id),
      .alu_src(alu_src_id),
      .result_src(result_src_id)
  );

  // Register File
  register_file regfile (
      .clk(clk),
      .rst(rst),
      .rs1_addr(rs1_id),
      .rs2_addr(rs2_id),
      .rs1_data(rs1_data_id),
      .rs2_data(rs2_data_id),
      .wr_en(reg_write_wb),
      .rd_addr(rd_wb),
      .rd_data(rd_data_wb)
  );

  // ID/EX Pipeline Register
  id_ex_reg id_ex (
      .clk(clk),
      .rst(rst),
      .stall(1'b0),
      .flush(flush_ex),
      .reg_write_in(reg_write_id),
      .mem_read_in(mem_read_id),
      .mem_write_in(mem_write_id),
      .branch_in(branch_id),
      .jump_in(jump_id),
      .alu_op_in(alu_op_id),
      .alu_src_in(alu_src_id),
      .result_src_in(result_src_id),
      .pc_in(pc_id),
      .rs1_data_in(rs1_data_id),
      .rs2_data_in(rs2_data_id),
      .imm_in(imm_id),
      .rd_in(rd_id),
      .rs1_in(rs1_id),
      .rs2_in(rs2_id),
      .funct3_in(funct3_id),
      .opcode_in(opcode_id),
      .reg_write_out(reg_write_ex),
      .mem_read_out(mem_read_ex),
      .mem_write_out(mem_write_ex),
      .branch_out(branch_ex),
      .jump_out(jump_ex),
      .alu_op_out(alu_op_ex),
      .alu_src_out(alu_src_ex),
      .result_src_out(result_src_ex),
      .pc_out(pc_ex),
      .rs1_data_out(rs1_data_ex),
      .rs2_data_out(rs2_data_ex),
      .imm_out(imm_ex),
      .rd_out(rd_ex),
      .rs1_out(rs1_ex),
      .rs2_out(rs2_ex),
      .funct3_out(funct3_ex),
      .opcode_out(opcode_ex)
  );


  // ========== EX Stage ==========

  assign pc_plus_4_ex = pc_ex + 4;
  assign pc_branch_target = pc_ex + imm_ex;

  always_comb begin
    case (forward_a)
      2'b00:   alu_forward_a = rs1_data_ex;  // From register file
      2'b01:   alu_forward_a = alu_result_mem;  // From EX/MEM (previous ALU result)
      2'b10:   alu_forward_a = rd_data_wb;  // From WB (oldest)
      default: alu_forward_a = rs1_data_ex;
    endcase

    case (forward_b)
      2'b00:   alu_forward_b = rs2_data_ex;  // From register file
      2'b01:   alu_forward_b = alu_result_mem;  // From EX/MEM (previous ALU result)
      2'b10:   alu_forward_b = rd_data_wb;  // From WB (oldest)
      default: alu_forward_b = rs2_data_ex;
    endcase
  end
  assign alu_in1 = alu_forward_a;
  assign alu_in2 = alu_src_ex ? imm_ex : alu_forward_b;

  // ALU
  alu alu (
      .a(alu_in1),
      .b(alu_in2),
      .alu_op(alu_op_ex),
      .result(alu_result_ex)
  );

  // Branch decision
  assign alu_zero = (alu_result_ex == 64'b0);

  always_comb begin
    case (funct3_ex)
      3'b000:  branch_taken = branch_ex && alu_zero;  // BEQ
      3'b001:  branch_taken = branch_ex && !alu_zero;  // BNE
      default: branch_taken = 1'b0;
    endcase
  end

  // EX/MEM Pipeline Register
  ex_mem_reg ex_mem (
      .clk(clk),
      .rst(rst),
      .stall(1'b0),
      .flush(1'b0),
      .reg_write_in(reg_write_ex),
      .mem_read_in(mem_read_ex),
      .mem_write_in(mem_write_ex),
      .result_src_in(result_src_ex),
      .pc_plus_4_in(pc_plus_4_ex),
      .alu_result_in(alu_result_ex),
      .rs2_data_in(alu_forward_b),
      .rd_in(rd_ex),
      .funct3_in(funct3_ex),
      .reg_write_out(reg_write_mem),
      .mem_read_out(mem_read_mem),
      .mem_write_out(mem_write_mem),
      .result_src_out(result_src_mem),
      .pc_plus_4_out(pc_plus_4_mem),
      .alu_result_out(alu_result_mem),
      .rs2_data_out(rs2_data_mem),
      .rd_out(rd_mem),
      .funct3_out(funct3_mem)
  );


  // ========== MEM Stage ==========

  // Data Memory
  data_memory #(
      .MEM_SIZE(1024)
  ) dmem (
      .clk(clk),
      .rst(rst),
      .mem_read(mem_read_mem),
      .mem_write(mem_write_mem),
      .mem_size(funct3_mem),
      .address(alu_result_mem),
      .write_data(rs2_data_mem),
      .read_data(mem_read_data)
  );

  // MEM/WB Pipeline Register
  mem_wb_reg mem_wb (
      .clk(clk),
      .rst(rst),
      .stall(1'b0),
      .flush(1'b0),
      .reg_write_in(reg_write_mem),
      .result_src_in(result_src_mem),
      .pc_plus_4_in(pc_plus_4_mem),
      .alu_result_in(alu_result_mem),
      .mem_data_in(mem_read_data),
      .rd_in(rd_mem),
      .reg_write_out(reg_write_wb),
      .result_src_out(result_src_wb),
      .pc_plus_4_out(pc_plus_4_wb),
      .alu_result_out(alu_result_wb),
      .mem_data_out(mem_data_wb),
      .rd_out(rd_wb)
  );


  // ========== WB Stage ==========

  always_comb begin
    case (result_src_wb)
      2'b00:   rd_data_wb = alu_result_wb;
      2'b01:   rd_data_wb = mem_data_wb;
      2'b10:   rd_data_wb = pc_plus_4_wb;
      default: rd_data_wb = alu_result_wb;
    endcase
  end


  // ========== Hazard Detection and Forwarding ==========

  hazard_unit hazard (
      .rs1_id(rs1_id),
      .rs2_id(rs2_id),
      .rd_ex(rd_ex),
      .mem_read_ex(mem_read_ex),
      .reg_write_ex(reg_write_ex),
      .rd_mem(rd_mem),
      .reg_write_mem(reg_write_mem),
      .rd_wb(rd_wb),
      .reg_write_wb(reg_write_wb),
      .branch_taken(branch_taken),
      .jump_ex(jump_ex),
      .stall_if(stall_if),
      .stall_id(stall_id),
      .flush_id(flush_id),
      .flush_ex(flush_ex)
  );

  forwarding_unit forward (
      .rs1_ex(rs1_ex),
      .rs2_ex(rs2_ex),
      .rd_mem(rd_mem),
      .reg_write_mem(reg_write_mem),
      .rd_wb(rd_wb),
      .reg_write_wb(reg_write_wb),
      .forward_a(forward_a),
      .forward_b(forward_b)
  );

endmodule
