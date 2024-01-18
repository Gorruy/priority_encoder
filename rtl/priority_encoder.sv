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
logic [PTR_SIZE - 1:0] pointer_shift;
logic [WIDTH - 1:0]    data_left_buf;

always_ff @(posedge clk_i)
  begin
    if ( srst_i == 1 )
      begin
        data_right_o <= '0;
        data_left_o  <= '0;
        data_val_o   <= 1'b0;
      end
    else
      begin
        if ( data_val_i )
          begin
            data_right_o <= (WIDTH)'( ~data_i + 1 ) & data_i;
            data_left_o  <= data_left_buf;
            data_val_o   <= 1'b1;
          end
        else
          begin
            data_right_o <= '0;
            data_left_o  <= '0;
            data_val_o   <= 1'b0;
          end
      end
  end

always_comb 
  begin 
    current_pointer = (PTR_SIZE)'(MIDDLE);
    pointer_shift   = (PTR_SIZE)'(MIDDLE >> 1);
    data_left_buf   = '0;
    if ( data_val_i ) 
      begin
        if ( data_i <= (WIDTH)'(1) )
          data_left_buf <= data_i;
        else
          begin
            for ( int i = 0; i <= PTR_SIZE; i++ )
              begin
                if ( ( data_i >> current_pointer ) == (WIDTH)'(1) )
                  break;
                else if ( ( data_i >> current_pointer ) == '0 )
                  current_pointer = current_pointer - pointer_shift;
                else
                  current_pointer = current_pointer + pointer_shift;
                pointer_shift = pointer_shift >> 1;
              end
            data_left_buf = data_i & ( (WIDTH)'(1) << current_pointer );
          end
        end
  end

endmodule
