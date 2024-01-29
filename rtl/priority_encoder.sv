module priority_encoder #(
  parameter WIDTH = 16
)(
  input  logic               clk_i,
  input  logic               srst_i,

  input  logic [WIDTH - 1:0] data_i,
  input  logic               data_val_i,

  output logic [WIDTH - 1:0] data_left_o,
  output logic [WIDTH - 1:0] data_right_o,
  output logic               data_val_o
);

logic [WIDTH - 1:0]    data_left_buf;
logic [WIDTH - 1:0]    data_right_buf;

always_ff @( posedge clk_i )
  begin
    if ( srst_i )
      data_val_o   <= 1'b0;
    else
      begin
        if ( data_val_i )
          data_val_o   <= 1'b1;
        else
          data_val_o <= 1'b0;
      end
  end

always_ff @( posedge clk_i )
  begin
    data_left_o  <= data_left_buf;
    data_right_o <= data_right_buf;
  end

assign data_right_buf = (WIDTH)'( ~data_i + 1 ) & data_i;

always_comb 
  begin 
    data_left_buf = '0;
    for ( int i = WIDTH; i >= 0; i-- )
      begin
        if ( data_i[i] )
          begin
            data_left_buf[i] = 1'b1;
            break;
          end
      end
  end

endmodule
