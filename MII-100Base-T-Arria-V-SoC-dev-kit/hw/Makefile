PRJ=MII-100Base-T-Arria-V-SoC-dev-kit

all:
	quartus_sh --flow compile $(PRJ)

clean:
	quartus_sh --clean $(PRJ)
	rm -f *.sopcinfo
	rm -f *.txt
	rm -f *.csv
	rm -f *.rpt
	rm -f *.qws

	rm -rf incremental_db
	rm -rf output_files
	rm -rf db

