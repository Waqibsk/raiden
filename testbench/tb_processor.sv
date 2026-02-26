`timescale 1ns / 1ps
// =================================================================
// raiden - TESTBENCH
// Features:
// 1. Zba Instructions (sh1add, sh2add, sh3add)
// 2. Data Hazards (Read-After-Write checking Forwarding between stages)
// 3. Load-Use Hazards (Checking Pipeline Stall)
// 4. Branching Logic (BEQ, BNE, taken & not‑taken)
// 5. Jump Instructions (JAL)
// 6. Basic memory read/write and register init
// =================================================================


module tb_processor;

  logic clk;
  logic rst;

  // Instantiate the processor
  riscv_pipelined cpu (
      .clk(clk),
      .rst(rst)
  );

  // Clock generation: 10ns period (100MHz)
  always #5 clk = ~clk;

  // Simulation control
  int cycle_count = 0;
  int max_cycles = 2000;
  bit max_cycles_reached = 1'b0;

  initial begin

    $dumpfile("waveform.vcd");

    $dumpvars(0, tb_processor);
  end

  initial begin
    $display("========================================");
    $display("RV64I-Zba PROCESSOR TESTBENCH");
    $display("========================================\n");

    // Initialize
    clk = 0;
    rst = 1;

    load_test_program();

    // Release reset
    #30;
    rst = 0;

    $display("Starting Execution...\n");

    #1000;  // Run for ~20 clock cycles

    // If we get here without hitting max_cycles, just continue to results
    $display("[Cycle reached ~20] Proceeding to results\n");

    // Display results
    #20;
    verify_results();
    $finish;
  end

  // =================================================================
  // HARDWARE PROGRAM LOADER
  // =================================================================

  task load_test_program();
    int addr = 0;

    // SETUP REGISTERS
    // x1 = 10
    cpu.imem.mem[addr++] = 32'h00A00093;  // addi x1, x0, 10
    // x2 = 20
    cpu.imem.mem[addr++] = 32'h01400113;  // addi x2, x0, 20

    // HAZARD TEST: RAW (Read After Write) 
    // If Forwarding is broken, x3 will be wrong (0 instead of 30)
    // No NOPs here x3 depends on x1 and x2 immediately
    cpu.imem.mem[addr++] = 32'h002081B3;  // add x3, x1, x2 (Expect 30)

    // Zba TEST: SH1ADD (Shift Left 1 + Add)
    // x4 = (x1 << 1) + x2 = (10*2) + 20 = 40
    cpu.imem.mem[addr++] = 32'h2020A233;  // sh1add x4, x1, x2 (Expect 40)

    // Zba HAZARD TEST
    // x5 uses x4 immediately (Forwarding check for Zba)
    // x5 = (x4 << 2) + x1 = (40*4) + 10 = 170
    cpu.imem.mem[addr++] = 32'h201242B3;  // sh2add x5, x4, x1 (Expect 170)

    // LOAD-USE HAZARD TEST 
    // Setup memory address 0 with value 99
    cpu.imem.mem[addr++] = 32'h06300313;  // addi x6, x0, 99
    cpu.imem.mem[addr++] = 32'h00603023;  // sd x6, 0(x0)

    // Load it back into x7
    cpu.imem.mem[addr++] = 32'h00003383;  // ld x7, 0(x0) (Expect 99)

    // USE IT IMMEDIATELY
    // This requires a 1-cycle STALL. Forwarding is not enough for Load-Use.
    // x8 = x7 + 1 = 100
    cpu.imem.mem[addr++] = 32'h00138413;  // addi x8, x7, 1 (Expect 100)

    // BRANCH TEST (Taken)
    // Branch if x1 != x2 (10 != 20). Should skip next instruction.
    cpu.imem.mem[addr++] = 32'h00209463;  // bne x1, x2, +8 (Skip next line)
    cpu.imem.mem[addr++] = 32'hDEADB4B3;  // add x9, x29, x27 (Should skip this)
    cpu.imem.mem[addr++] = 32'h00100493;  // addi x9, x0, 1 (Target of Branch)

    // BRANCH NOT-TAKEN TEST
    // BEQ x1, x2 (10 vs 20) not taken, next instruction should execute
    cpu.imem.mem[addr++] = 32'h00208463;  // beq x1, x2, +8
    cpu.imem.mem[addr++] = 32'h00100513;  // addi x10, x0, 1  (should run)
    cpu.imem.mem[addr++] = 32'h00000013;  // NOP

    // JUMP TEST (JAL)
    // Jump over one instruction, write return address into x11
    cpu.imem.mem[addr++] = 32'h008005EF;  // jal x11, 8
    cpu.imem.mem[addr++] = 32'h00100593;  // addi x11, x0, 1  (should be skipped)
    cpu.imem.mem[addr++] = 32'h00100613;  // addi x12, x0, 1  (target of jump)

    // EXTRA ZBA & HAZARD
    // Use sh3add and immediately a dependent add to check forwarding again
    // x14 uses x13 immediately (rd=x14, rs1=x13, rs2=x13)

    // sh3add x13, x2, x1
    // Formula: x13 = (x2 << 3) + x1  -->  (18 * 8) + 26 = 170
    cpu.imem.mem[addr++] = 32'h201166B3;  // Expect 170

    // add x14, x13, x13 
    // Formula: x14 = x13 + x13  -->  170 + 170 = 340
    cpu.imem.mem[addr++] = 32'h00D68733;  // Expect 340


    // END
    cpu.imem.mem[addr++] = 32'h0000006F;  // JAL x0, 0 (Infinite Loop)
    // // Add NOPs to allow pipeline to drain before terminating
    cpu.imem.mem[addr++] = 32'h00000013;  // NOP
    cpu.imem.mem[addr++] = 32'h00000013;  // NOP
    cpu.imem.mem[addr++] = 32'h00000013;  // NOP

    $display("Program Loaded: %0d instructions", addr);
  endtask

  // =================================================================
  // VERIFICATION
  // =================================================================
  task verify_results();
    int errors = 0;

    $display("\n========================================");
    $display("FINAL REGISTER VERIFICATION");
    $display("========================================");

    // check_reg(RegNum, ExpectedVal, TestName, ErrorCount)
    check_reg(1, 10, "Init x1", errors);
    check_reg(2, 20, "Init x2", errors);

    // Hazard Check
    check_reg(3, 30, "RAW Hazard (ADD)", errors);

    // Zba Check
    check_reg(4, 40, "Zba sh1add", errors);
    check_reg(5, 170, "Zba Hazard (sh2add)", errors);

    // Load-Use Check
    check_reg(7, 99, "Load Data", errors);
    check_reg(8, 100, "Load-Use Hazard", errors);

    // Branch Check
    check_reg(9, 1, "Branch Taken (BNE)", errors);
    check_reg(10, 1, "Branch Not-Taken (BEQ)", errors);
    check_reg(11, 64, "JAL Return Address (x11)", errors);  // should contain PC+4 of jump (60+4=64)
    check_reg(12, 1, "JAL Target (x12)", errors);
    check_reg(13, 170, "Zba sh3add", errors);
    check_reg(14, 340, "Zba Hazard (sh3add forward)", errors);

    if (errors == 0) begin
      $display("\n SUCCESS: ALL TESTS PASSED ");
      $display("Processor handles Zba, Hazards, and Branching correctly.");
    end else begin
      $display("\n FAILURE: %0d ERRORS FOUND ✗✗✗", errors);
      $display("Tips:");
      $display(" - If Hazard/Zba tests fail: Check Forwarding Unit.");
      $display(" - If Load-Use test fails: Check Hazard Detection Unit (Stall).");
    end
  endtask

  task check_reg(int reg_idx, logic [63:0] expected, string name, inout int err);
    if (cpu.regfile.registers[reg_idx] !== expected) begin
      $display("FAIL: %s (x%0d)", name, reg_idx);
      $display("      Expected: %0d | Actual: %0d", expected, cpu.regfile.registers[reg_idx]);
      err++;
    end else begin
      $display("PASS: %s (x%0d) = %0d", name, reg_idx, expected);
    end
  endtask

endmodule
