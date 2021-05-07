PRJ=verilog_ethernet_tb

all:
	vsim -do $(PRJ).do
	# vsim -c -do $(PRJ).do

clean:
	if [ -d work ]; then vdel -lib work -all; fi;
	if [ -d altera_mf ]; then vdel -lib altera_mf -all; fi;
	rm -f transcript *.wlf
	rm -f *.vstf
	rm -f vsim.*

