module top_tb;

  parameter NUMBER_OF_TEST_RUNS = 1000;
  parameter WIDTH      = 131;

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

  mailbox #( logic [WIDTH - 1:0] ) output_data    = new();
  mailbox #( logic [WIDTH - 1:0] ) input_data     = new();
  mailbox #( logic [WIDTH - 1:0] ) generated_data = new();

  function void display_error ( input logic [WIDTH - 1:0] in,  
                                input logic [WIDTH - 1:0] out_l,
                                input logic [WIDTH - 1:0] out_r
                              );
    $error( "sended data:%b, found left bit:%b, found right bit:%b", in, out_l, out_r );

  endfunction

  task raise_transaction_strobe( input logic [WIDTH - 1:0] data_to_send ); 
    
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

  task compare_data ( mailbox #( logic [WIDTH - 1:0] ) input_data,
                      mailbox #( logic [WIDTH - 1:0] ) output_data
                    );

    logic [WIDTH - 1:0] i_data;
    logic [WIDTH - 1:0] o_data_l;
    logic [WIDTH - 1:0] o_data_r;
    
    while ( input_data.num() )
      begin
        output_data.get( o_data_r );
        output_data.get( o_data_l );
        input_data.get( i_data );

        if ( o_data_l === o_data_r && o_data_l === i_data ) // check if original data was only with one set bit
          continue;

        if ( ( i_data === '0 && ( o_data_l !== '0 || o_data_r !== '0 ) ) || // input_data zero and output is not
            ( ( o_data_l === '0 || o_data_r === '0 ) && i_data != '0 ) )    // input_data is not zero but output is
            test_succeed = '0;

        if ( ( $clog2(o_data_l) + 1 !== $clog2(i_data) ) ||   // check if there is ones to the left of found and ref leftmost bits 
            ( o_data_l << ( WIDTH - $clog2(o_data_l) ) ) )    // check if there is ones to the right of found leftmost bit
            test_succeed = 0;

        if ( ( (-i_data) & i_data ) !== o_data_r )
            test_succeed = 0;

        if ( !test_succeed )
          begin
            display_error( i_data, o_data_l , o_data_r );
            return;
          end
      end

  endtask

  task generate_transactions ( mailbox #( logic [WIDTH - 1:0] ) generated_data );

    logic [WIDTH - 1:0] data_to_send;
    
    repeat (NUMBER_OF_TEST_RUNS)
      begin
        data_to_send = $urandom_range( 2**WIDTH - 1, 0 );
        generated_data.put( data_to_send );
      end

    for ( int i = 0; i < WIDTH; i++ ) begin
      data_to_send = 1 << i;
      generated_data.put( data_to_send );
    end

    data_to_send = '1;
    generated_data.put( data_to_send );

  endtask

  task send_data ( mailbox #( logic [WIDTH - 1:0] ) input_data,
                   mailbox #( logic [WIDTH - 1:0] ) generated_data
                 );
    while ( generated_data.num() )
      begin
        logic [WIDTH - 1:0] data_to_send;

        generated_data.get( data_to_send );
        
        raise_transaction_strobe( data_to_send );
        
        input_data.put( data_to_send );
      end

  endtask

  task read_data ( mailbox #( logic [WIDTH - 1:0] ) output_data );
    
    logic [WIDTH - 1:0] recieved_right_data;
    logic [WIDTH - 1:0] recieved_left_data;

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
                test_succeed = 1;
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

