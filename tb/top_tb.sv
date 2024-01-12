module top_tb;

  parameter NUMBER_OF_TEST_RUNS = 100;
  parameter DATA_BUS_WIDTH      = 16;

  bit                          clk;
  logic                        srst;
  bit                          srst_done;

  logic                        data;
  logic                        data_val;

  logic [DATA_BUS_WIDTH - 1:0] deser_data;
  logic                        deser_data_val;

  // flag to indicate if there is an error
  bit test_succeed;

  initial forever #5 clk = !clk;

  default clocking cb @( posedge clk );
  endclocking

  initial 
    begin
      srst <= 1'b0;
      ##1;
      srst <= 1'b1;
      ##1;
      srst <= 1'b0;
      srst_done = 1'b1;
    end

  deserializer #(
    .DATA_BUS_WIDTH ( DATA_BUS_WIDTH )
  ) DUT ( 
    .clk_i            ( clk              ),
    .srst_i           ( srst             ),
    .deser_data_o     ( deser_data       ),
    .deser_data_val_o ( deser_data_val   ),
    .data_i           ( data             ),
    .data_val_i       ( data_val         )
  );

  typedef logic queued_data_t[$:DATA_BUS_WIDTH - 1];

  mailbox #( queued_data_t ) output_data    = new(1);
  mailbox #( queued_data_t ) input_data     = new(1);
  mailbox #( queued_data_t ) generated_data = new(1);

  function void display_error ( input queued_data_t in,  
                                input queued_data_t out
                              );
    $display( "expected values:%p, result value:%p", in, out );

  endfunction

  task raise_transaction_strobe( logic data_to_send ); 
    
    // data comes at random moment
    int delay;
    delay = $urandom_range(10, 0);
    ##(delay);

    data     <= data_to_send;
    data_val <= 1'b1;
    ## 1;
    data     <= '0;
    data_val <= '0; 

  endtask

  task compare_data ( mailbox #( queued_data_t ) input_data,
                      mailbox #( queued_data_t ) output_data
                    );
    
    queued_data_t i_data;
    queued_data_t o_data;

    input_data.get( i_data );
    output_data.get( o_data );
    
    for ( int i = DATA_BUS_WIDTH; i > 0; i-- ) begin
      if ( i_data[i - 1] != o_data[i - 1] )
        begin
          display_error( i_data, o_data );
          test_succeed <= 1'b0;
          return;
        end
    end
    
  endtask

  task generate_transaction ( mailbox #( queued_data_t ) generated_data );
    
    queued_data_t data_to_send;

    data_to_send = {};

    for ( int i = 0; i < DATA_BUS_WIDTH; i++ ) begin
      data_to_send.push_back( $urandom_range( 1, 0 ) );
    end

    generated_data.put( data_to_send );

  endtask

  task send_data ( mailbox #( queued_data_t ) input_data,
                   mailbox #( queued_data_t ) generated_data
                 );

    queued_data_t data_to_send;
    queued_data_t exposed_data;

    exposed_data = {};
    generated_data.get( data_to_send );
    
    for ( int i = 0; i < DATA_BUS_WIDTH; i++ ) begin
      raise_transaction_strobe( data_to_send[$] );
      exposed_data.push_back( data_to_send.pop_back() );
    end

    input_data.put( exposed_data );

  endtask

  task read_data ( mailbox #( queued_data_t ) output_data );
    
    queued_data_t recieved_data;

    recieved_data = {};
    
    wait ( deser_data_val )
    recieved_data <= { << { deser_data } };

    output_data.put(recieved_data);

  endtask

  initial begin
    data         <= '0;
    data_val     <= 0;
    test_succeed <= 1;

    $display("Simulation started!");
    wait( srst_done );

    repeat ( NUMBER_OF_TEST_RUNS )
    begin
      fork
        generate_transaction( generated_data );
        send_data( input_data, generated_data );
        read_data( output_data );
        compare_data( input_data, output_data );
      join
    end

    $display("Simulation is over!");
    if ( test_succeed )
      $display("All tests passed!");
    $stop();
  end



endmodule

