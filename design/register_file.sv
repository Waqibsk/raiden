// Register File 
// RISC-V has 32 registers: x0 (always 0) through x31
// Can read 2 registers and write 1 register per cycle

module register_file (
    input logic clk,
    input logic rst,

    // Read ports (2 simultaneous reads)
    input  logic [ 4:0] rs1_addr,  // Source register 1 address 
    input  logic [ 4:0] rs2_addr,  // Source register 2 address
    output logic [63:0] rs1_data,  // Data from register rs1
    output logic [63:0] rs2_data,  // Data from register rs2

    // Write port (1 write per cycle)

    input logic        wr_en,    // Write enable (1 = write, 0 = don't write)
    input logic [ 4:0] rd_addr,  // Destination register address
    input logic [63:0] rd_data   // Data to write
);

  // 32 registers, each 64 bits wide
  logic [63:0] registers[31:0];

  // Read operations (combinational - immediate)
  assign rs1_data = (rs1_addr != 5'b0 && rs1_addr == rd_addr && wr_en) ? rd_data : registers[rs1_addr];
  assign rs2_data = (rs2_addr != 5'b0 && rs2_addr == rd_addr && wr_en) ? rd_data : registers[rs2_addr];

  // Write operation (sequential - on clock edge)
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // Reset all registers to 0
      for (int i = 0; i < 32; i++) begin
        registers[i] <= 64'b0;
      end
    end else if (wr_en && rd_addr != 5'b0) begin
      // Write only if enabled and not writing to x0
      registers[rd_addr] <= rd_data;
    end
  end

endmodule
