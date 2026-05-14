// Generated ASCON state/context storage skeleton.
// profile=single_320_register, storage=single_context_regs
// context_count=1, contexts_per_engine=1
// interleave_depth=1, shadow_state=false
// state_bits_total=320, memory_bits=0
module tt_ascon_state #(
  parameter int CONTEXT_COUNT = 1,
  parameter int CONTEXT_ID_BITS = 1
) (
  input  logic clk,
  input  logic rst_n,
  input  logic [CONTEXT_ID_BITS-1:0] context_id_i,
  input  logic state_we_i,
  input  logic [319:0] state_i,
  output logic [319:0] state_o
);

  logic [319:0] state_mem [0:CONTEXT_COUNT-1];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_o <= 320'b0;
    end else begin
      if (state_we_i) begin
        state_mem[context_id_i] <= state_i;
      end
      state_o <= state_mem[context_id_i];
    end
  end
endmodule
