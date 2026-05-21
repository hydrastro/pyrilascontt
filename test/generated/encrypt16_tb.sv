`timescale 1ns/1ps
`default_nettype none

module tb;
  reg clk = 0;
  reg rst_n = 0;
  reg strobe = 0;
  reg [3:0] cmd = 0;
  reg [7:0] din = 0;

  wire [7:0] dout;
  wire ready;
  wire done;
  wire tag_ok;
  wire busy;

  localparam [127:0] KEY     = 128'h000102030405060708090a0b0c0d0e0f;
  localparam [127:0] NONCE   = 128'h101112131415161718191a1b1c1d1e1f;
  localparam [127:0] PT      = 128'h202122232425262728292a2b2c2d2e2f;
  localparam [127:0] EXP_CT  = 128'h52fd20d46d5c40056bf294aff2892cf1;
  localparam [127:0] EXP_TAG = 128'h3442b7197ba19564a24b9354c007e5bb;

  tt_ascon_core dut (
    .clk(clk),
    .rst_n(rst_n),
    .strobe_i(strobe),
    .cmd_i(cmd),
    .data_i(din),
    .data_o(dout),
    .ready_o(ready),
    .done_o(done),
    .tag_ok_o(tag_ok),
    .busy_o(busy)
  );

  always #5 clk = ~clk;

  function [7:0] get_byte_128;
    input [127:0] value;
    input integer index;
    begin
      case (index)
        0:  get_byte_128 = value[127:120];
        1:  get_byte_128 = value[119:112];
        2:  get_byte_128 = value[111:104];
        3:  get_byte_128 = value[103: 96];
        4:  get_byte_128 = value[ 95: 88];
        5:  get_byte_128 = value[ 87: 80];
        6:  get_byte_128 = value[ 79: 72];
        7:  get_byte_128 = value[ 71: 64];
        8:  get_byte_128 = value[ 63: 56];
        9:  get_byte_128 = value[ 55: 48];
        10: get_byte_128 = value[ 47: 40];
        11: get_byte_128 = value[ 39: 32];
        12: get_byte_128 = value[ 31: 24];
        13: get_byte_128 = value[ 23: 16];
        14: get_byte_128 = value[ 15:  8];
        15: get_byte_128 = value[  7:  0];
        default: get_byte_128 = 8'h00;
      endcase
    end
  endfunction

  function [7:0] expected_out;
    input integer index;
    begin
      if (index < 16)
        expected_out = get_byte_128(EXP_CT, index);
      else
        expected_out = get_byte_128(EXP_TAG, index - 16);
    end
  endfunction

  task send_cmd_byte;
    input [3:0] c;
    input [7:0] b;
    begin
      @(posedge clk);
      while (!ready) @(posedge clk);

      cmd <= c;
      din <= b;
      strobe <= 1'b1;

      @(posedge clk);
      strobe <= 1'b0;
      cmd <= 4'h0;
      din <= 8'h00;

      wait(done === 1'b1);
      @(posedge clk);
    end
  endtask

  task send_cmd_only;
    input [3:0] c;
    begin
      send_cmd_byte(c, 8'h00);
    end
  endtask

  integer i;
  reg [7:0] exp_b;

  initial begin
    $display("encrypt16_tb: start");

    repeat (3) @(posedge clk);
    rst_n <= 1'b1;
    repeat (3) @(posedge clk);

    send_cmd_only(4'hf); // reset core

    for (i = 0; i < 16; i = i + 1)
      send_cmd_byte(4'h1, get_byte_128(KEY, i));

    for (i = 0; i < 16; i = i + 1)
      send_cmd_byte(4'h2, get_byte_128(NONCE, i));

    for (i = 0; i < 16; i = i + 1)
      send_cmd_byte(4'h4, get_byte_128(PT, i));

    send_cmd_only(4'h6); // final / compute

    if (tag_ok !== 1'b1) begin
      $display("FAIL tag_ok not set");
      $finish(1);
    end

    for (i = 0; i < 32; i = i + 1) begin
      send_cmd_only(4'h7);
      exp_b = expected_out(i);
      if (dout !== exp_b) begin
        $display("FAIL byte %0d got=%02x exp=%02x", i, dout, exp_b);
        $finish(1);
      end
    end

    $display("PASS");
    $finish(0);
  end

endmodule

`default_nettype wire
