`timescale 1ns / 1ps

module keyboard(
  input clk,
  input clrn,
  input ps2_clk,
  input ps2_data,
  output [7:0] code,
  input out_ready,
  output out_valid,
  input of_clear,
  output of);
  (*mark_debug = "true"*)reg [7:0] data_buffer [3:0];
  (*mark_debug = "true"*)reg [1:0] wptr_r, rptr_r;
  (*mark_debug = "true"*)wire kb_out_valid;
  (*mark_debug = "true"*)wire kb_out_ready;
  (*mark_debug = "true"*)wire [7:0] data;
  (*mark_debug = "true"*)reg [7:0] tmp_code_r;
  (*mark_debug = "true"*)wire full = wptr_r + 2'b1 == rptr_r;
  (*mark_debug = "true"*)wire kb_overflow;
  (*mark_debug = "true"*)wire empty = wptr_r == rptr_r;
  ps2_keyboard keyboard(.clk(clk),.clrn(clrn),.ps2_clk(ps2_clk),.ps2_data(ps2_data),.data(data),.out_valid(kb_out_valid),.out_ready(kb_out_ready),.overflow(kb_overflow),.of_clear(of_clear));
  
  always@(posedge clk) begin
    if(clrn == 0) begin
      wptr_r <= 0;
      rptr_r <= 0;
      tmp_code_r <= 0;
    end
    else begin
      if(kb_out_valid && kb_out_ready)begin
        if(full == 0) begin
          if(data == 8'hf0)begin
            data_buffer[wptr_r] <= tmp_code_r; 
            wptr_r <= wptr_r + 1;
          end
          else begin
            tmp_code_r <= data;
          end
        end
      end
    end
    
    if(out_valid && out_ready) begin
      rptr_r = rptr_r + 1;
    end
  end
  
  assign kb_out_ready = full == 0 && clrn == 1;
  assign out_valid = !empty;
  assign of = kb_overflow;
  assign code = data_buffer[rptr_r];
endmodule

module ps2_keyboard(clk,
                    clrn,
                    ps2_clk,
                    ps2_data,
                    data,
                    out_valid,
                    out_ready,
                    overflow,
                    of_clear);
  input clk,clrn,ps2_clk,ps2_data; 
  input out_ready,of_clear; 
  (*mark_debug = "true"*)output [7:0] data;
  (*mark_debug = "true"*)output reg out_valid;
  output reg overflow; // fifo overflow
  // internal signal, for test
  (*mark_debug = "true"*)reg [9:0] buffer; // ps2_data bits
  reg [7:0] fifo[7:0]; // data fifo
  (*mark_debug = "true"*)reg [2:0] w_ptr,r_ptr; // fifo write and read pointers
  (*mark_debug = "true"*)reg [3:0] count; // count ps2_data bits
 // detect falling edge of ps2_clk
  (*mark_debug = "true"*)reg [2:0] ps2_clk_sync;

  always @(posedge clk) begin
    ps2_clk_sync <= {ps2_clk_sync[1:0],ps2_clk};
  end

  (*mark_debug = "true"*)wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

  always @(posedge clk) begin
    if (clrn == 0) begin // reset
      count <= 0; w_ptr <= 0; r_ptr <= 0; overflow <= 0; out_valid<= 0;
    end
    else begin
      if (out_valid) begin // read to output next data
        if(out_ready == 1'b1) //read next data
        begin
          r_ptr <= r_ptr + 3'b1;
          if(w_ptr==(r_ptr+1'b1)) //empty
            out_valid <= 1'b0;
        end
      end
      if (sampling) begin
        if (count == 4'd10) begin
          if ((buffer[0] == 0) && (ps2_data) && (^buffer[9:1])) begin // odd parity
            fifo[w_ptr] <= buffer[8:1]; // kbd scan code
            w_ptr <= w_ptr+3'b1;
            out_valid <= 1'b1;
            overflow <= overflow | (r_ptr == (w_ptr + 3'b1));
          end
          count <= 0; // for next
        end
        else begin
          buffer[count] <= ps2_data; // store ps2_data
          count <= count + 3'b1;
        end
      end
      else if(of_clear == 1) begin
        overflow <= 0;
      end
    end
  end
  assign data = fifo[r_ptr]; //always set output data

 endmodule