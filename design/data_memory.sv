// Data Memory 

module data_memory #(
    parameter MEM_SIZE = 1024
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [ 2:0] mem_size,    // 0=byte, 1=half, 2=word, 3=double
    input  logic [63:0] address,     // Memory address
    input  logic [63:0] write_data,  // Data to write
    output logic [63:0] read_data    // Data read from memory
);

  // Memory array: each entry is 64 bits
  logic [63:0] mem[0:MEM_SIZE-1];

  // Word address
  logic [63:0] word_addr;
  assign word_addr = address[63:3];

  // Read operation
  always_comb begin
    if (mem_read && word_addr < MEM_SIZE) begin
      read_data = mem[word_addr];
    end else begin
      read_data = 64'b0;
    end
  end

  // Write operation 
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // Initialize memory to 0
      for (int i = 0; i < MEM_SIZE; i++) begin
        mem[i] <= 64'b0;
      end
    end else if (mem_write && word_addr < MEM_SIZE) begin
      mem[word_addr] <= write_data;
    end
  end

endmodule
