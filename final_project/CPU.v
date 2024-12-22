// Your code
module FSM(clk, rst_n, next, state);
input clk, rst_n, in;
output out;

localparam ID = 5'd0;
localparam IF = 5'd1;
localparam EX = 5'd2;
localparam MEM = 5'd3;
localparam WB = 5'd4;

reg [4:0] state, state_next;
assign out = state;

always @(*) begin
  case(state)
    ID: state_next = next ? ID : IF;
    IF: state_next = next ? IF : EX;
    EX: state_next = next ? EX : MEM;
    MEM: state_next = next ? MEM : WB;
    WB: state_next = next ? WB : ID;
  end
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    state <= ID;
  end else begin
    state <= state_next;
  end
end

endmodule

module CU(clk, rst_n, opc, out);
input clk, rsrt_n, opt;
output out;
endmodule

module CPU(clk,
            rst_n,
            // For mem_D (data memory)
            wen_D,
            addr_D,
            wdata_D,
            rdata_D,
            // For mem_I (instruction memory (text))
            addr_I,
            rdata_I);

    input         clk, rst_n ;
    // For mem_D
    output        wen_D  ;
    output [31:0] addr_D ;
    output [31:0] wdata_D;
    input  [31:0] rdata_D;
    // For mem_I
    output [31:0] addr_I ;
    input  [31:0] rdata_I;
    
    //---------------------------------------//
    // Do not modify this part!!!            //
    // Exception: You may change wire to reg //
    reg    [31:0] PC          ;              //
    wire   [31:0] PC_nxt      ;              //
    wire          regWrite    ;              //
    wire   [ 4:0] rs1, rs2, rd;              //
    wire   [31:0] rs1_data    ;              //
    wire   [31:0] rs2_data    ;              //
    wire   [31:0] rd_data     ;              //
    //---------------------------------------//

    // modes
    localparam lw = 5'd0;
    localparam sub = 5'd1;
    localparam addi = 5'd2;
    localparam slli = 5'd3;
    localparam srli = 5'd4;
    localparam srai = 5'd5;
    localparam slti = 5'd6;
    localparam beq = 5'd7;
    localparam bne = 5'd8;
    localparam bge = 5'd9;
    localparam blt = 5'd10;
    localparam jal = 5'd11;
    localparam jalr = 5'd12;
    localparam auipc = 5'd13;
    localparam lui = 5'd14;
    localparam mul = 5'd15;
    localparam div = 5'd16;
    localparam remu = 5'd17;

    // Todo: other wire/reg
    reg [4:0] mode;
    reg [31:0] instruction;
    reg [6:0] opcode;
    reg [2:0] func3;
    reg [6:0] func7;
    reg [31:0] alu_lhs;
    reg [31:0] alu_rhs;
    reg [31:0] alu_result;
    reg [31:0] alu_result_next;
    reg [31:0] wb_data;
    reg [31:0] wb_data_next;


    //---------------------------------------//
    // Do not modify this part!!!            //
    reg_file reg0(                           //
        .clk(clk),                           //
        .rst_n(rst_n),                       //
        .wen(regWrite),                      //
        .a1(rs1),                            //
        .a2(rs2),                            //
        .aw(rd),                             //
        .d(rd_data),                         //
        .q1(rs1_data),                       //
        .q2(rs2_data));                      //
    //---------------------------------------//

    // Todo: any combinational/sequential circuit

    assign addr_I = PC;
    assign opcode = instruction[6:0];
    assign func3 = instruction[14:12];
    assign func7 = instruction[31:25];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rs = instruction[11:7];
    assign addr_D = alu_result;
    assign wdata_D = rs2_data;

    always @(*) begin
      // parsing mode
      case(opcode) 
        7'd3: mode = lw;
        7'd19: begin
          case(func3) begin
            3'd0: mode = addi;
            3'd1: mode = slli;
            3'd2: mode = slti;
            3'd5: begin
              case(func7) 
                7'd0: mode = srli;
                7'd32: mode = srai;
              end
            end
          end
        end
        7'd23: mode = auipc;
        7'd35: mode: sw;
        7'd51: begin
          case(func3)
            3'd0: begin
              case(func7)
                7'd0: add;
                7'd32: sub;
              end
            end
          end
        end
        7'd55: mode = lui;
        7'd99: begin
          case(func3)
            3'd0: mode = beq;
            3'd1: mode = bne;
            3'd2: mode = blt;
            3'd3: mode = bge;
          end
        end
        7'd103: mode = jalr;
        7'd111: mode = jal;
      end
      // alu
      case(mode)
        lw: begin
          alu_result_next = rs1_data + instruction[31:20];
        end
        sw: begin
          alu_result_next = rs1_data + {instruction[31:20], instruction[11:7]};
        end
        add: begin
          alu_result_next = rs1_data + rs2_data;
        end
        sub: begin
          alu_result_next = rs1_data - rs2_data;
        end
        slli: begin
          alu_result_next = rs1_data << {19'd0, instruction[31:20]};
        end
        srli: begin
          alu_result_next = rs1_data >> {19'd0, instruction[31:20]};
        end
        srai: begin
          alu_result_next = rs1_data >>> {19'd0, instruction[31:20]};
        end
        slti: begin
          alu_result_next = (rs1_data < {19'd0, instruction[31:20]}) ? 32'b1 : 32'b0;
        end
        beq: begin
          alu_result_next = (rs1_data == rs2_data) ? 32'b1: 32'b0;
        end
        bne: begin
          alu_result_next = (rs1_data != rs2_data) ? 32'b1: 32'b0;
        end
        jalr: begin
          alu_result_next = PC + 4;
        end
        jal: begin
          alu_result_next = PC + 4;
        end
        auipc: begin
          alu_result_next = PC + {instruction[31:12], 12'b0};
        end
        lui: begin
          alu_result_next = {instruction[31:12], 12'b0};
        end
        mul: begin
          alu_result_next = (rs1_data * rs2_data) & 32'hffffffff;
        end
        div: begin
          alu_result_next = rs1_data / rs2_data;
        end
        remu: begin
          alu_result_next = rs1_data % rs2_data;
        end
      end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
            
        end
        else begin
            PC <= PC_nxt;
            
        end
    end
endmodule

// Do not modify the reg_file!!!
module reg_file(clk, rst_n, wen, a1, a2, aw, d, q1, q2);

    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth

    input clk, rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] d;
    input [addr_width-1:0] a1, a2, aw;

    output [BITS-1:0] q1, q2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign q1 = mem[a1];
    assign q2 = mem[a2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (aw == i)) ? d : mem[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end
    end
endmodule

module mulDiv(clk, rst_n, valid, ready, mode, in_A, in_B, out);
    // Todo: your HW2

endmodule
