module deserializer_top (
  input  logic        clk_i,
  input  logic        srst_i,

  input  logic        data_i,
  input  logic        data_val_i,
  output logic [15:0] deser_data_o,
  output logic        deser_data_val_o
);

  logic        srst;

  logic        data;
  logic        data_val;

  logic [15:0] deser_data;
  logic        deser_data_val;

  always_ff @( posedge clk_i )
    begin
      srst     <= srst_i;
      data     <= data_i;
      data_val <= data_val_i; 
    end 

  deserializer #(
    .DATA_BUS_WIDTH   ( 16             )
  ) deserializer (
    .clk_i            ( clk_i          ),
    .srst_i           ( srst           ),

    .data_i           ( data           ),
    .data_val_i       ( data_val       ),

    .deser_data_o     ( deser_data     ),
    .deser_data_val_o ( deser_data_val ),  
);

  always_ff @( posedge clk_i )
    begin
      deser_data_o     <= deser_data;
      deser_data_val_o <= deser_data_val;
    end


endmodule
