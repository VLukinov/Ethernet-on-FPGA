PRJ=SFPP-1000Base-T-10GBase-T-Arria10-SoM

all:
	quartus_sh --flow compile $(PRJ)

clean:
	quartus_sh --clean $(PRJ)

	rm -rf ./ip/ethernet_phy/ethernet_phy
	rm -rf ./ip/xcvr_1g_pll/xcvr_1g_pll
	rm -rf ./ip/xcvr_10g_pll/xcvr_10g_pll
	rm -rf ./ip/xcvr_reset_control/xcvr_reset_control
	rm -rf ./ip/xgmii_pll/xgmii_pll

	rm -f *.sopcinfo
	rm -f *.txt
	rm -f *.csv
	rm -f *.rpt
	rm -f *.qws
	rm -f *.xml

	rm -rf greybox_tmp
	rm -rf incremental_db
	rm -rf output_files
	rm -rf db

