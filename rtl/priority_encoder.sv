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

localparam MIDDLE   = WIDTH / 2;
localparam PTR_SIZE = $clog2(WIDTH);

logic [PTR_SIZE - 1:0] current_pointer;
logic [PTR_SIZE - 1:0] shift;

always_ff @(posedge clk_i)
  begin
    if ( srst_i == 1 )
      begin
        data_right_o <= '0;
        data_val_o   <= 0;
      end
    else
      begin
        if ( data_val_i == 1 )
          begin
            data_right_o <= (~data_i + 1) & data_i;
            data_val_o   <= 1;
          end
        else
          begin
            data_right_o <= '0;
            data_val_o   <= 0;
          end
      end
  end

always_comb 
  begin 
    current_pointer = (PTR_SIZE)'(MIDDLE);
    shift           = (PTR_SIZE)'(MIDDLE >> 1);
    if ( data_val_i == 1 ) 
      begin
        for ( int i = 0; i < PTR_SIZE; i++ )
          begin
            if ( ( data_i >> current_pointer ) == 1)
              break;
            else if ( ( data_i >> current_pointer ) == 0 )
              current_pointer = current_pointer - shift;
            else
              current_pointer = current_pointer + shift;
            shift = shift >> 1;
          end
        data_left_o = (data_i >> current_pointer) << current_pointer;
      end
  end

endmodule
