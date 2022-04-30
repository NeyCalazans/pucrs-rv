/*!\file memory.sv
 * PUCRS-RV VERSION - 1.0 - Public Release
 *
 * Distribution:  September 2021
 *
 * Willian Nunes   <willian.nunes@edu.pucrs.br>
 * Marcos Sartori  <marcos.sartori@acad.pucrs.br>
 * Ney calazans    <ney.calazans@pucrs.br>
 *
 * Research group: GAPH-PUCRS  <>
 *
 * \brief
 * Memory acess Module of Execute Unit.
 *
 * \detailed
 * Memory is a module that composes the Execute unit of the PUCRS-RV 
 * processor and is responsible for performing a data read from memory 
 * in Read instructions or preparing the signals for a write in memory 
 * in Write instrutions.
 */

import my_pkg::*;

module memoryUnit(
    input logic         clk,
    input logic [31:0]  opA,                            // Base Address
    input logic [31:0]  opB,                            // Offset
    input logic [31:0]  data,                           // Data to be Written in memory
    input instruction_type i,                           // Instruction type
    output logic [31:0] read_address,                   // Read Memory Address
    output logic        read,                           // Signal that allows memory read
    input logic [31:0]  DATA_in,                        // Data received from memory
    output logic [31:0] write_address,                  // Adrress to Write in memory
    output logic [31:0] DATA_wb,                        // Data to be Written in Register Bank or in memory
    output logic        write,                          // Signal that allows memory write
    output logic [1:0]  size,                           // Signal that indicates the size of Write in memory(byte(1),half(2),word(4))
    output logic        we_out);                        // Write enable signal to register bank, in Stores=0 and in Loads=1

    logic write_int, we_int;
    logic [31:0] DATA_write, write_address_2;
    logic [1:0] size_int;

///////////////////////////////////// generate all signals for read or write ////////////////////////////////////////////////////////////////////////
    always_comb begin
        if(i==OP0 | i==OP1) begin                        // Load Byte signed and unsigned (LB | LBU)
            write_int <= 0;
            read <= 1;
            DATA_write <= '0;
            size_int <= 2'b00;

        end else if(i==OP2 | i==OP3) begin               // Load Half(16b) signed and unsigned (LH | LHU)
            write_int <= 0;
            read <= 1;
            DATA_write <= '0;
            size_int <= 2'b00;

        end else if(i==OP4) begin                        // Load Word(32b) (LW)
            write_int <= 0;
            read <= 1;
            DATA_write <= '0;
            size_int <= 2'b00;

        end else if(i==OP7) begin                       // Store Byte (SB)
            write_int <= 1;
            read <= 0;
            DATA_write[31:8] <= 24'h000000;
            DATA_write[7:0] <= data[7:0];               // Only the less significant byte is fullfilled with data, the rest is fullfilled with zeros
            size_int <= 2'b01;

        end else if(i==OP6) begin                       // Store Half(16b) (SH)
            write_int <= 1;
            read <= 0;
            DATA_write[31:16] <= 16'h0000;    
            DATA_write[15:0] <= data[15:0];             // Only the less significant half is fullfilled with data, the rest is fullfilled with zeros
            size_int <= 2'b10;

        end else if(i==OP5) begin                       // Store Word (SW)
            write_int <= 1;
            read <= 0;
            DATA_write[31:0] <= data[31:0];  
            size_int <= 2'b11;
        end
        //////////////////////////////////////////////
        if(i==OP0 | i==OP1 | i==OP2 | i==OP3 | i==OP4)
            read_address = opA + opB;
        else 
            read_address = '0;
    end

///////////////////////////////////////////////// Data Write Back parsing ///////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if(i==OP0 | i==OP1) begin                       // LB | LBU
            if(DATA_in[7]==1 & i==OP0)                  // Signal extension
                DATA_wb[31:8] <= 24'hFFFFFF;
            else                                        // 0's extension
                DATA_wb[31:8] <= 24'h000000;
            DATA_wb[7:0] <= DATA_in[7:0];

        end else if(i==OP2 | i==OP3) begin              // LH | LHU
            if(DATA_in[15]==1 & i==OP2)                 // Signal extension
                DATA_wb[31:16] <= 16'hFFFF;
            else                                        // 0's extension
                DATA_wb[31:16] <= 16'h0000; 
            DATA_wb[15:0] <= DATA_in[15:0];

        end else if(i==OP4)                             // LW
            DATA_wb <= DATA_in;

        else                                            // STORES
            DATA_wb <= DATA_write;
    end

///////////////////////////////////////////////// Write enable to register bank ///////////////////////////////////////////////////////////////////////////
    always_comb
        if(i==OP5 || i==OP6 || i==OP7)                  // Stores do not write in regbank
            we_int<='0;
        else
            we_int<='1;

///////////////////////////////////////////////// Output registers //////////////////////////////////////////////////////////////////////////////////
    always@(posedge clk) begin
        write_address <= opA + opB;
        write <= write_int;
        size <= size_int;
        we_out <= we_int;
    end

endmodule