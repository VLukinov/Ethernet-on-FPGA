SFP+ USXGMII NBase-T example of using the "verilog-ethernet" library on Arria 10 SoM
(ReFLEX CES ACHILLES Arria 10 SoC SoM - https://www.reflexces.com/intel-fpga/arria-10-intel-fpga/arria-10-soc-som)

Connect to the SFP PORT0 connector and run netcat -u 192.168.1.128 1234 to open a UDP connection to port 1234.
Any text entered into netcat will be echoed back after pressing enter.

In order for this example to work, 125 MHz must be applied to the i_ref_clock (clk_xcvr[3]) input.
To do this, you need to configure the MAX10 system controller.

