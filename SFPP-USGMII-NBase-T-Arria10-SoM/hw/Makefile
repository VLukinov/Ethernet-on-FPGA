PRJ=SFPP-USGMII-NBase-T-Arria10-SoM

all:
	quartus_sh --flow compile $(PRJ)

clean:
	quartus_sh --clean $(PRJ)

	rm -rf ./ip/usxgmii_eth_phy/usxgmii_eth_phy
	rm -rf ./ip/xcvr_reset_control/xcvr_reset_control
	rm -rf ./ip/xcvr_pll/xcvr_pll
	rm -rf ./ip/usxgmii_eth_pll/usxgmii_eth_pll

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

