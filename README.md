# KeyBoard
```
module keyboard(
  input clk,	//输入时钟
  input clrn,	//清零信号，低有效
  input ps2_clk,//键盘接口输入时钟
  input ps2_data,//键盘接口输入数据
  output [7:0] code,//输出当前输出的键码
  input out_ready,//输出握手的ready信号
  output out_valid,//输入握手的valid信号
  input of_clear,//overflow信号清零
  output of);	//输出的overflow信号
```

键盘中设置了缓冲区用于存放按下还未处理的键码数据，在data_buffer中。当data_buffer满的时候，便会输出overflow信号，用于标记缓冲区溢出了。输入of_clear的时候，将overflow信号清零。Verilog实现的键盘控制器。

