//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1.3 (lin64) Build 2644227 Wed Sep  4 09:44:18 MDT 2019
//Date        : Sat Dec  5 17:40:24 2020
//Host        : tama running 64-bit Ubuntu 20.04.1 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (LED);
  output [7:0] LED;
  
  wire [7:0] LED;
  
  wire [31:0]GPIO_0_tri_o;
  wire [31:0]GPIO_1_tri_i;
  wire pl_clk0_0;
  wire pl_resetn0_0;

  design_1 design_1_i
       (.GPIO_0_tri_o(GPIO_0_tri_o),
        .GPIO_1_tri_i(GPIO_1_tri_i),
        .pl_clk0_0(pl_clk0_0),
        .pl_resetn0_0(pl_resetn0_0));

  assign LED = GPIO_0_tri_o[7:0];

//  vio_0 vio_0_i (
//    .clk(pl_clk0_0),           // input wire clk
//    .probe_in0(GPIO_0_tri_o),  // input wire [31 : 0] probe_in0
//    .probe_out0(GPIO_1_tri_i)  // output wire [31 : 0] probe_out0
//  );

endmodule
