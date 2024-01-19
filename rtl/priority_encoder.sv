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

always_ff @(posedge clk_i)
  begin
    if ( srst_i )
      begin
        data_right_o <= '0;
        data_left_o  <= '0;
        data_val_o   <= 1'b0;
      end
    else
      begin
        if ( data_val_i )
          begin
            data_right_o <= data_right_buf;
            data_left_o  <= data_left_buf;
            data_val_o   <= 1'b1;
          end
        else
          data_val_o   <= 1'b0;
      end
  end

assign data_right_buf = (WIDTH)'( ~data_i + 1 ) & data_i;

always_comb 
  begin 
    data_left_buf   = '0;

    if ( data_val_i ) 
      begin
        for ( int i = WIDTH - 1; i >= 0; i-- )
          begin
            if ( data_i[i] )
              begin
                data_left_buf = (WIDTH)'(1 << i);
                break;
              end
          end
      end
  end

endmodule
