// Your code
module FSM(clk, rst_n, next, out);
  input clk, rst_n, next;
  output [4:0] out;
  localparam ID = 5'd0;
  localparam MULDIV_WAIT = 5'd7;
  localparam IF = 5'd1;
  localparam EX = 5'd2;
  localparam MEM = 5'd3;
  localparam MEM_WAIT = 5'd4;
  localparam WB = 5'd5;
  localparam PC = 5'd6;

  reg [4:0] state, state_next;
  assign out = state;

  always @(*) begin
    case(state)
      ID: state_next = next ? MULDIV_WAIT : ID;
      MULDIV_WAIT: state_next = next ? IF : MULDIV_WAIT;
      IF: state_next = next ? EX : IF;
      EX: state_next = next ? MEM : EX;
      MEM: state_next = next ? MEM_WAIT : MEM;
      MEM_WAIT: state_next = next ? WB : MEM_WAIT;
      WB: state_next = next ? PC : WB;
      PC: state_next = next ? ID : PC;
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    //$display(out);
    //$display(state);
    if(!rst_n) begin
      state <= ID;
    end else begin
      state <= state_next;
    end
  end

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
    reg    [31:0] PC_nxt      ;              //
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
    localparam sw = 5'd18;
    localparam add = 5'd19;

    // Todo: other wire/reg
    reg [4:0] mode;
    reg [31:0] instruction;
    wire [6:0] opcode;
    //reg [6:0] opcode;
    wire [2:0] func3;
    wire [6:0] func7;
    reg [31:0] alu_lhs;
    reg [31:0] alu_rhs;
    reg [31:0] alu_result;
    reg [31:0] alu_result_next;
    reg [31:0] wb_data;
    reg [31:0] wb_data_next;
    wire [4:0] state;
    reg wen_d;
    reg next;
    reg regwrite;
    // for muldiv
    wire [31:0] muldiv_in_A;
    wire [31:0]  muldiv_in_B;
    wire valid;
    reg muldiv_valid;
    wire muldiv_mode;
    reg muldiv_mode_reg;
    wire [63:0] muldiv_out;
    //wire ready;
    wire muldiv_ready;
    reg muldiv_result;

    FSM fsm(
      .clk(clk),
      .rst_n(rst_n),
      .next(next),
      .out(state));

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
    
    //---------------------------------------//
    mulDiv muldiv(                           //
        .clk(clk),                           //
        .rst_n(rst_n),                       //
        .valid(valid), 
        .in_A(muldiv_in_A),
        .in_B(muldiv_in_B),
        .mode(muldiv_mode), 
        .ready(muldiv_ready),
        .out_data(muldiv_out));
    //---------------------------------------//

    // Todo: any combinational/sequential circuit

    // muldiv
    assign muldiv_in_A = rs1_data;
    assign muldiv_in_B = rs2_data;
    assign valid = muldiv_valid;
    assign muldiv_mode = muldiv_mode_reg;

    // architecture
    assign addr_I = PC;
    assign wen_D = wen_d;
    assign opcode = instruction[6:0];
    assign func3 = instruction[14:12];
    assign func7 = instruction[31:25];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];
    assign addr_D = alu_result;
    assign wdata_D = rs2_data;
    assign rd_data = wb_data;
    assign regWrite = regwrite;

    always @(*) begin
      muldiv_result = muldiv_out;
      //opcode = instruction[14:12];
      // parsing mode
      case(opcode) 
        7'd3: mode = lw;
        7'd19: begin
          case(func3) 
            3'd0: mode = addi;
            3'd1: mode = slli;
            3'd2: mode = slti;
            3'd5: begin
              case(func7) 
                7'd0: mode = srli;
                7'd32: mode = srai;
              endcase
            end
          endcase
        end
        7'd23: mode = auipc;
        7'd35: mode = sw;
        7'd51: begin
          case(func3)
            3'd0: begin
              case(func7)
                7'd0: mode = add;
                7'd1: mode = mul;
                7'd32: mode = sub;
              endcase
            end
            3'd5: mode = div;
            3'd7: mode = remu;
          endcase
        end
        7'd55: mode = lui;
        7'd99: begin
          case(func3)
            3'd0: mode = beq;
            3'd1: mode = bne;
            3'd4: mode = blt;
            3'd5: mode = bge;
          endcase
        end
        7'd103: mode = jalr;
        7'd111: mode = jal;
      endcase
      // alu
      case(mode)
        lw: begin
          alu_result_next = rs1_data + {{21{instruction[31]}}, instruction[30:20]};
          PC_nxt = PC + 4;
          wb_data_next = rdata_D;
        end
        sw: begin
          alu_result_next = rs1_data + {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
          PC_nxt = PC + 4;
        end
        add: begin
          alu_result_next = rs1_data + rs2_data;
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        sub: begin
          alu_result_next = $signed(rs1_data) - $signed(rs2_data);
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        addi: begin
          alu_result_next = rs1_data + {{21{instruction[31]}}, instruction[30:20]};
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        slli: begin
          alu_result_next = rs1_data << instruction[24:20];
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        srli: begin
          alu_result_next = rs1_data >> instruction[24:20];
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        srai: begin
          alu_result_next = $signed(rs1_data) >>> instruction[24:20];
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        slti: begin
          alu_result_next = ($signed(rs1_data) < $signed(instruction[31:20])) ? 32'b1 : 32'b0;
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        beq: begin
          alu_result_next = (rs1_data == rs2_data) ? 32'b1: 32'b0;
          if(rs1_data == rs2_data) begin
            PC_nxt = PC + {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
          end else begin
            PC_nxt = PC + 4;
          end
        end
        bge: begin
          alu_result_next = ($signed(rs1_data) >= $signed(rs2_data)) ? 32'b1: 32'b0;
          if($signed(rs1_data) >= $signed(rs2_data)) begin
            PC_nxt = PC + {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
          end else begin
            PC_nxt = PC + 4;
          end
        end
        blt: begin
          alu_result_next = (rs1_data < rs2_data) ? 32'b1: 32'b0;
          if($signed(rs1_data) < $signed(rs2_data)) begin
            PC_nxt = PC + {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
          end else begin
            PC_nxt = PC + 4;
          end
        end
        bne: begin
          alu_result_next = (rs1_data != rs2_data) ? 32'b1: 32'b0;
          if(rs1_data != rs2_data) begin
            PC_nxt = PC + {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
          end else begin
            PC_nxt = PC + 4;
          end
        end
        jalr: begin
          alu_result_next = PC + 4;
          PC_nxt = rs1_data + {{21{instruction[31]}}, instruction[30:20]};
          //PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        jal: begin
          alu_result_next = PC + 4;
          //PC_nxt = PC + $signed({instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0});
          PC_nxt = PC + {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
          wb_data_next = alu_result;
        end
        auipc: begin
          alu_result_next = PC + {instruction[31:12], 12'b0};
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        lui: begin
          alu_result_next = {instruction[31:12], 12'b0};
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
        end
        mul: begin
          //alu_result_next = (rs1_data * rs2_data) & 32'hffffffff;
          //alu_result_next = $signed(rs1_data) * $signed(rs2_data);
          //alu_result_next = muldiv_result[31:0];
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
          muldiv_mode_reg = 1;
        end
        div: begin
          //alu_result_next = rs1_data / rs2_data;
          //alu_result_next = muldiv_result[31:0];
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
          muldiv_mode_reg = 0;
        end
        remu: begin
          //alu_result_next = rs1_data % rs2_data;
          //alu_result_next = muldiv_result[63:32];
          PC_nxt = PC + 4;
          wb_data_next = alu_result;
          muldiv_mode_reg = 0;
        end
      endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
            next <= 1;
            wen_d <= 0;
            regwrite <= 0;
            if(mode == sw) begin
              wen_d <= 0;
            end
        end
        else begin
            case(state)
              5'd0: begin
                next <= 1;
                instruction <= rdata_I;
                regwrite <= 0;
              end
              5'd7: begin
                if(mode == mul || mode == div || mode == remu) begin
                  muldiv_valid <= 1;
                  next <= muldiv_ready;
                end else begin
                  next <= 1;
                end
              end
              5'd1: begin
                muldiv_valid <= 0;
                if(mode == mul || mode == div || mode == remu) begin
                 if(muldiv_ready) begin
                   if(mode == mul || mode == div) begin
                     alu_result_next <= muldiv_out[31:0];
                   end else begin
                     alu_result_next <= muldiv_out[63:32];
                   end
                   //alu_result <= alu_result_next;
                 end
                  if(next) begin
                    //$display("%h", muldiv_out);
                    next <= 1;
                    //alu_result <= alu_result_next;
                    //$display("%h", alu_result_next);
                  end else begin
                    next <= muldiv_ready;
                  end
                end else begin
                  next <= 1;
                end
                //$display("%h", muldiv_out);
              end
              5'd2: begin
                next <= 1;
                alu_result <= alu_result_next;
                /*
                if(mode != mul && mode != div && mode != remu) begin
                  alu_result <= alu_result_next;
                end
                */
              end
              5'd3: begin
                //$display(alu_result);
                next <= 1;
                //$display(mode);
                if(mode == sw) begin
                  wen_d <= 1;
                end
              end
              5'd4: begin
                next <= 1;
                wb_data <= wb_data_next;
              end
              5'd5: begin
                //$display("foo");
                //PC <= PC_nxt;
                //$display(PC);
                next <= 1;
                wen_d <= 0;
                case(mode)
                  lw: regwrite <= 1;
                  add: regwrite <= 1;
                  sub: regwrite <= 1;
                  addi : regwrite <= 1;
                  slli : regwrite <= 1;
                  srli : regwrite <= 1;
                  srai : regwrite <= 1;
                  slti : regwrite <= 1;
                  jal : regwrite <= 1;
                  jalr : regwrite <= 1;
                  lui : regwrite <= 1;
                  mul: regwrite <= 1;
                  div: regwrite <= 1;
                  remu: regwrite <= 1;
                  auipc: regwrite <= 1;
                  default: regwrite <= 0;
                endcase
              end
              5'd6: begin
                next <= 1;
                //$display(PC);
                PC <= PC_nxt;
              end
            endcase
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

module DIV (
  input clk,
  input rst_n,
  input [31:0] A, // remainder
  input [31:0] B, // devisor
  input on,
  output [63:0] out_data,
  output ready
);

reg [63:0] tmp;
reg [63:0] rem = 64'd0;
reg [5:0] count;
reg [31:0] div = 32'd0;
reg over;
reg ready;

assign out_data = {over, tmp[63:33], tmp[31:0]};

always @(*) begin
  if (rem >= {div, 32'd0}) begin
    tmp <= ((rem - {div, 32'd0}) << 1) + 64'd1;
  end else begin
    tmp <= rem << 1;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    count <= 6'd0;
    ready <= 0;
    rem <= 64'd0;
    div <= 32'd0;
  end else if (!on) begin
    count <= 6'd0;
    ready <= 0;
    rem <= {31'd0, (A), 1'd0};
    div <= B;
    over <= (A < B) && A[31];
  end else if (count <= 6'd31) begin
    if (rem >= {div, 32'd0}) begin
      rem <= ((rem - {div, 32'd0}) << 1) + 64'd1;
    end else begin
      rem <= rem << 1;
    end
    count <= count + 6'd1;
    if (count == 6'd30) begin
      ready <= 1;
    end
  end
end
endmodule

module MUL (
  input clk,
  input rst_n,
  input [31:0] A, // multiplier
  input [31:0] B, // multiplicand
  input on,
  output [63:0] out_data,
  output ready
);

reg [63:0] out;
reg [63:0] tmp;
reg [5:0] count;
//reg [31:0] tmp_A = 32'd0;
reg [31:0] tmp_B = 32'd0;
reg ready;

assign out_data = tmp;

always @(*) begin
  if (out[0]) begin 
    tmp = (out >> 1) + ({(tmp_B), 32'd0} >> 1);
  end else begin
    tmp = out >> 1;
  end
  //$display("%h", tmp);
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    count <= 6'd0;
    out <= {32'd0, (A)};
    ready <= 0;
    tmp_B <= B;
  end else if (!on) begin
    count <= 6'd0;
    out <= {32'd0, (A)};
    ready <= 0;
    tmp_B <= B;
    //tmp_B <= {{0, (B)}, (A)}
    //tmp_A <= A;
  end else if (count <= 6'd31) begin
    out <= tmp;
    count <= count + 6'd1;
    if (count == 6'd30) begin
      ready <= 1;
    end
  end
end
endmodule

module mulDiv(
  input clk,
  input rst_n,
  input valid,
  output ready,
  input mode,
  input [31:0] in_A,
  input [31:0] in_B,
  output [63:0] out_data);
// ===============================================
//                    wire & reg
// ===============================================

reg [63:0] out_data;
//reg [31:0] tmp_0;
//reg [31:0] tmp_1;
//reg [31:0] A;
//reg [31:0] B;
reg ready;
reg [63:0] out;
reg loaded;
//reg [3:0] mode_in;
reg mul_on = 0;
reg [5:0] count = 0;
wire [63:0] mul_out;
wire mul_ready;
reg div_on = 0;
wire [63:0] div_out;
wire div_ready;

MUL mul (
  .clk (clk),
  .rst_n (rst_n),
  .A (in_A),
  .B (in_B),
  .out_data (mul_out),
  .ready (mul_ready),
  .on (mul_on)
);

DIV div (
  .clk (clk),
  .rst_n (rst_n),
  .A (in_A),
  .B (in_B),
  .out_data (div_out),
  .ready (div_ready),
  .on (div_on)
);

// ===============================================
//                   combinational
// ===============================================

always @(*) begin
end

// ===============================================
//                    sequential
// ===============================================

always @(posedge clk or negedge rst_n) begin
  /*
  if(ready) begin
    $display(out_data);
  end
  */
  if (!rst_n) begin 
    out_data <= 64'd0;
    //A <= 32'd0;
    //B <= 32'd0;
    //mode_in <= 4'd0;
    ready <= 1'd0;
    loaded <= 0;
  end else if (ready) begin
    ready <= 0;
    loaded <= 0;
    mul_on <= 0;
    div_on <= 0;
    count <= 6'd0;
  end else if (valid) begin 
    //$display("%h", in_A);
    //$display("%h", in_B);
    /*
    if (!loaded) begin
      mode_in <= mode_in;
    end
    */
    loaded <= 1;
    //$display(mode);
    //$display(mode_in);
    if (mode) begin
      //count <= 6'd1_in;
      mul_on <= 1;
    end else begin
      div_on <= 1;
    end
  end else if (mul_on) begin
    //$display("here");
    out_data <= mul_out;
    ready <= mul_ready;
  end else if (div_on) begin
    out_data <= div_out;
    ready <= div_ready;
  end
end
endmodule
