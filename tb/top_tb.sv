module top_tb;

  parameter NUMBER_OF_TEST_RUNS = 1000;
  parameter WIDTH      = 17;

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

  typedef logic [WIDTH - 1:0] data_t;

  mailbox #( data_t ) output_data    = new();
  mailbox #( data_t ) input_data     = new();
  mailbox #( data_t ) generated_data = new();

  function void display_error ( input data_t in,  
                                input data_t out_l,
                                input data_t out_r
                              );
    $error( "sended data:%b, found left bit:%b, found right bit:%b", in, out_l, out_r );

  endfunction

  task raise_transaction_strobe( input data_t data_to_send ); 
    
    // data comes at random moment
    int delay;
    delay = $urandom_range(5, 0);
    ##(delay);

    data       = data_to_send;
    data_val_i = 1'b1;
    ## 1;
    data       = '0;
    data_val_i = 1'b0; 

  endtask

  function data_t leftmost_bit_find ( input data_t i_data );
    data_t left; 
    left  = '0; 

    for ( int i = WIDTH - 1; i >= 0; i-- )
      begin
        if ( i_data[i] === 1'b1 )
          begin
            left[i] = 1'b1;
            return left;
          end
      end

    return left;
  endfunction
  
  function data_t rigthmost_bit_find ( input data_t i_data );
    data_t right;
    right = '0;

    for ( int i = 0; i < WIDTH; i++ )
      begin
        if ( i_data[i] === 1'b1 )
          begin
            right[i] = 1'b1;
            return right;
          end
      end

    return right;
  endfunction

  task compare_data ( mailbox #( data_t ) input_data,
                      mailbox #( data_t ) output_data
                    );

    data_t i_data;
    data_t o_data_l;
    data_t o_data_r;
    
    while ( input_data.num() )
      begin
        output_data.get( o_data_r );
        output_data.get( o_data_l );
        input_data.get( i_data );

        if ( leftmost_bit_find(i_data) !== o_data_l ||
             rigthmost_bit_find(i_data) !== o_data_r )
          begin
            test_succeed = 1'b0;
            display_error( i_data, o_data_l, o_data_r );
            return;
          end
      end

  endtask

  task generate_transactions ( mailbox #( data_t ) generated_data );

    data_t data_to_send;
    
    repeat (NUMBER_OF_TEST_RUNS)
      begin
        data_to_send = $urandom_range( 2**WIDTH - 1, 0 );
        generated_data.put( data_to_send );
      end

    for ( int i = 0; i < WIDTH + 1; i++ ) begin
      data_to_send = (WIDTH)'(1) << i;
      generated_data.put( data_to_send );
    end

    data_to_send = '1;
    generated_data.put( data_to_send );

  endtask

  task send_data ( mailbox #( data_t ) input_data,
                   mailbox #( data_t ) generated_data
                 );
    while ( generated_data.num() )
      begin
        data_t data_to_send;

        generated_data.get( data_to_send );
        
        raise_transaction_strobe( data_to_send );
        
        input_data.put( data_to_send );
      end

  endtask

  task read_data ( mailbox #( data_t ) output_data );
    
    data_t recieved_right_data;
    data_t recieved_left_data;

    int time_without_data;
    
    forever
      begin
        @( posedge clk );
        if ( data_val_o === 1'b1 )
          begin
            recieved_left_data  = data_left;
            recieved_right_data = data_right;
      
            output_data.put( recieved_right_data );
            output_data.put( recieved_left_data );

            time_without_data = 0;
          end
        else
          begin
            if ( time_without_data == 11)
              begin
                test_succeed = 1'b1;
                break;
              end
            else
              time_without_data += 1;
          end
      end

  endtask

  initial begin
    data           <= '0;
    data_val_i     <= 1'b0;
    test_succeed   <= 1'b1;

    $display("Simulation started!");
    generate_transactions( generated_data );
    wait( srst_done === 1'b1 );

    fork
      send_data( input_data, generated_data );
      read_data( output_data );
    join

    compare_data( input_data, output_data );
    $display("Simulation is over!");
    if ( test_succeed )
      $display("All tests passed!");
    $stop();
  end



endmodule

