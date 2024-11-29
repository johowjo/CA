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

module ALU (
  input           clk,
  input           rst_n,
  input           valid,
  input   [31:0]  in_A,
  input   [31:0]  in_B,
  input   [3:0]   mode,
  output          ready,
  output  [63:0]  out_data
);

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
  /*
  if (!loaded) begin
    mode_in = mode;
  end
  */
  //A = in_A;
  //B = in_B;
  case(mode) 
    4'd0: begin
      out = {32'd0, $signed(in_A) + $signed(in_B)};
      if (in_A[31] && in_B[31]) begin
        if (!out[31]) begin
          out = {32'd0, 32'h80000000};
        end else begin
          //out = tmp_0;
        end
      end else if (!in_A[31] && !in_B[31]) begin
        if(out[31]) begin
          out = {32'd0, 32'h7fffffff};
        end else begin
          //out = tmp_0;
        end
      end else begin
        //out = tmp_0;
      end
    end
    4'd1: begin
      out = {32'd0, $signed(in_A) - $signed(in_B)};
      if (in_A[31] && !in_B[31]) begin
        if (!out[31]) begin
          out = {32'd0, 32'h80000000};
        end else begin
          //out = tmp_1;
        end
      end else if (!in_A[31] && in_B[31]) begin
        if(out[31]) begin
          out = {32'd0, 32'h7fffffff};
        end else begin
          //out = tmp_1;
        end
      end else begin
        //out = tmp_1;
      end
    end
    4'd2: out = {32'd0, (in_A & in_B)};
    4'd3: out = {32'd0, (in_A | in_B)};
    4'd4: out = {32'd0, (in_A ^ in_B)};
    4'd5: out = {63'd0, (in_A == in_B)};
    4'd6: out = {63'd0, ($signed(in_A) >= $signed(in_B))};
    4'd7: out = {32'd0, (in_A >> in_B)};
    4'd8: out = {32'd0, (in_A << in_B)};
    default: out = 64'd0;
  endcase
  /*
  $display("=======================");
  $display("%b", mode);
  $display("%h", A);
  $display("%h", B);
  $display("%h", out);
  */
end

// ===============================================
//                    sequential
// ===============================================

always @(posedge clk or negedge rst_n) begin
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
    /*
    if (!loaded) begin
      mode_in <= mode_in;
    end
    */
    loaded <= 1;
    //$display(mode);
    //$display(mode_in);
    if (mode <= 4'd8) begin
      //$display("here");
      out_data <= out;
      ready <= 1;
    end else if (mode == 4'd9) begin
      //count <= 6'd1_in;
      mul_on <= 1;
    end else if (mode == 4'd10) begin
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
 /*
   if (ready) begin
     ready <= 0;
     loaded <= 0;
     mul_on <= 0;
     div_on <= 0;
     count <= 6'd0;
   end
   */
end
endmodule
