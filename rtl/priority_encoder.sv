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

localparam MIDDLE = $clog2(WIDTH) >> 1;

logic [(MIDDLE << 1) - 1:0] pointer;

always_ff @(posedge clk_i)
  begin
    if ( srst_i == 1 )
      begin
        data_left_o  <= '0;
        data_right_o <= '0;
        data_val_o   <= 0;
      end
    else
      begin
        pointer <= (MIDDLE - 1)'(MIDDLE - 1);
        if ( data_val_i == 1 )
          begin
            data_right_o <= (~data_i + 1) & data_i;
            for ( int i = 0; i < MIDDLE; i++ )
              begin
                if ( ( data_i >> pointer ) == 1)
                  break;
                else if ( ( data_i >> pointer )== 0 )
                  pointer <= pointer - ( pointer >> 1 );
                else
                  pointer <= pointer + ( ( WIDTH - 1 - pointer ) >> 1 );
              end
            data_left_o <= { data_i >> pointer };
          end
        else
          begin
            data_left_o  <= '0;
            data_right_o <= '0;
            data_val_o   <= 0;
          end
      end
  end

endmodule
