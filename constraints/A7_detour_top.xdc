### Nexys N4 to Nexys A7 XDC conversion script: 
### Author : Sharath Krishnan - sharath@usc.edu 

set_property PACKAGE_PIN E3 [get_ports ClkPort]							

	set_property IOSTANDARD LVCMOS33 [get_ports ClkPort]

	create_clock -add -name ClkPort -period 10.00 [get_ports ClkPort]

set_property PACKAGE_PIN J15 [get_ports {SW0}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {SW0}]

set_property PACKAGE_PIN L16 [get_ports {SW1}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {SW1}]

set_property PACKAGE_PIN M13 [get_ports {SW2}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {SW2}]

set_property PACKAGE_PIN R15 [get_ports {SW3}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {SW3}]

set_property PACKAGE_PIN R17 [get_ports {SW4}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {SW4}]

set_property PACKAGE_PIN H17 [get_ports {LD0}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD0}]

set_property PACKAGE_PIN K15 [get_ports {LD1}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD1}]

set_property PACKAGE_PIN J13 [get_ports {LD2}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD2}]

set_property PACKAGE_PIN N14 [get_ports {LD3}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD3}]

set_property PACKAGE_PIN R18 [get_ports {LD4}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD4}]

set_property PACKAGE_PIN V17 [get_ports {LD5}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD5}]

set_property PACKAGE_PIN U17 [get_ports {LD6}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD6}]

set_property PACKAGE_PIN U16 [get_ports {LD7}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {LD7}]

set_property PACKAGE_PIN T10 [get_ports {CA}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {CA}]

set_property PACKAGE_PIN R10 [get_ports {CB}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {CB}]

set_property PACKAGE_PIN K16 [get_ports {CC}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {CC}]

set_property PACKAGE_PIN K13 [get_ports {CD}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {CD}]

set_property PACKAGE_PIN P15 [get_ports {CE}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {CE}]

set_property PACKAGE_PIN T11 [get_ports {CF}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {CF}]

set_property PACKAGE_PIN L18 [get_ports {CG}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {CG}]

set_property PACKAGE_PIN H15 [get_ports {DP}] 
	set_property IOSTANDARD LVCMOS33 [get_ports DP]

set_property PACKAGE_PIN J17 [get_ports {AN0}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN0}]

set_property PACKAGE_PIN J18 [get_ports {AN1}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN1}]

set_property PACKAGE_PIN T9 [get_ports {AN2}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN2}]

set_property PACKAGE_PIN J14 [get_ports {AN3}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN3}]

set_property PACKAGE_PIN P14 [get_ports {AN4}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN4}]

set_property PACKAGE_PIN T14 [get_ports {AN5}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN5}]

set_property PACKAGE_PIN K2 [get_ports {AN6}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN6}]

set_property PACKAGE_PIN U13 [get_ports {AN7}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {AN7}]

set_property PACKAGE_PIN N17 [get_ports {BtnC}] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnC]

set_property PACKAGE_PIN L13 [get_ports QuadSpiFlashCS]					

	set_property IOSTANDARD LVCMOS33 [get_ports QuadSpiFlashCS]

set_property PACKAGE_PIN L18 [get_ports RamCS]					

	set_property IOSTANDARD LVCMOS33 [get_ports RamCS]

set_property PACKAGE_PIN H14 [get_ports MemOE]					

	set_property IOSTANDARD LVCMOS33 [get_ports MemOE]

set_property PACKAGE_PIN R11 [get_ports MemWR]					

	set_property IOSTANDARD LVCMOS33 [get_ports MemWR]

