module top_tb;

  parameter NUMBER_OF_TEST_RUNS = 100;
  parameter WIDTH      = 16;

  bit                 clk;
  logic               srst;

  logic [WIDTH - 1:0] data;
  logic               data_val_i;
  logic [WIDTH - 1:0] data_left;
  logic [WIDTH - 1:0] data_right;
  logic               data_val_o;

  // flag to indicate if there is an error
  bit test_succeed;

  logic srst_done;

  initial forever #5 clk = !clk;

  default clocking cb @( posedge clk );
  endclocking

  initial 
    begin
      srst      <= 1'b0;
      ##1;
      srst      <= 1'b1;
      ##1;
      srst      <= 1'b0;
      srst_done <= 1'b1;
    end

  priority_encoder #(
    .WIDTH        ( WIDTH      )
  ) DUT ( 
    .clk_i        ( clk        ),
    .srst_i       ( srst       ),
    .data_i       ( data       ),
    .data_val_o   ( data_val_o ),
    .data_left_o  ( data_left  ),
    .data_right_o ( data_right ),
    .data_val_i   ( data_val_i )
  );

  typedef logic queued_data_t[$:WIDTH - 1];

  mailbox #( queued_data_t ) output_data    = new(2);
  mailbox #( queued_data_t ) input_data     = new(1);
  mailbox #( queued_data_t ) generated_data = new(1);

  function void display_error ( input queued_data_t in,  
                                input queued_data_t out
                              );
    $display( "expected values:%p, result value:%p", in, out );

  endfunction

  task raise_transaction_strobe( input queued_data_t data_to_send ); 
    
    // data comes at random moment
    int delay;
    delay = $urandom_range(10, 0);
    ##(delay);

    data       <= { << {data_to_send} };
    data_val_i <= 1;
    ## 1;
    data       <= '0;
    data_val_i <= '0; 

  endtask

  task compare_data ( mailbox #( queued_data_t ) input_data,
                      mailbox #( queued_data_t ) output_data
                    );
    
    queued_data_t i_data;
    queued_data_t o_data_l;
    queued_data_t o_data_r;

    input_data.get( i_data );
    output_data.get( o_data_l );
    output_data.get( o_data_r );

    if ( (i_data & o_data_l) <  )
    
  endtask

  task generate_transaction ( mailbox #( queued_data_t ) generated_data );
    
    queued_data_t data_to_send;

    data_to_send = {};

    for ( int i = 0; i < WIDTH; i++ ) begin
      data_to_send.push_back( $urandom_range( 1, 0 ) );
    end

    generated_data.put( data_to_send );

  endtask

  task send_data ( mailbox #( queued_data_t ) input_data,
                   mailbox #( queued_data_t ) generated_data
                 );

    queued_data_t data_to_send;

    generated_data.get( data_to_send );
    
    raise_transaction_strobe( data_to_send );

    input_data.put( data_to_send );

  endtask

  task read_data ( mailbox #( queued_data_t ) output_data );
    
    queued_data_t recieved_right_data;
    queued_data_t recieved_left_data;

    recieved_right_data = {};
    recieved_left_data  = {};
    
    wait ( data_val_o )
    recieved_right_data <= { << { data_right } };
    recieved_left_data  <= { << { data_left } };

    output_data.put( recieved_right_data );
    output_data.put( recieved_left_data );

  endtask

  initial begin
    data           <= '0;
    data_val_i     <= 0;
    test_succeed   <= 1;

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

