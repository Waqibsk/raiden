// Instruction Memory 

module instruction_memory #(
    parameter MEM_SIZE = 1024
) (
    input  logic [63:0] pc,        
    output logic [31:0] instruction  
);

  // Memory array: each entry is 32 bits
  logic [31:0] mem[0:MEM_SIZE-1];

  // Calculate word address 
  logic [63:0] word_addr;
  assign word_addr   = pc[63:2];  

  // Read instruction
  assign instruction = (word_addr < MEM_SIZE) ? mem[word_addr] : 32'h0000_0013;
  // Default to NOP (addi x0, x0, 0) if out of bounds

  initial begin
    // Fill with NOPs initially
    for (int i = 0; i < MEM_SIZE; i++) begin
      mem[i] = 32'h0000_0013; 
    end
  end

  task load_program(input string filename);
    $readmemh(filename, mem);
  endtask

endmodule

