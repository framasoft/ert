EXTRACTFILES=utilities/locales_files.txt
EN=themes/default/lib/EthercalcRevisionTool/I18N/en.po
FR=themes/default/lib/EthercalcRevisionTool/I18N/fr.po
XGETTEXT=carton exec local/bin/xgettext.pl
CARTON=carton exec
REAL_ERT=script/application
ERT=script/ethercalc_revision_tool

locales:
	$(XGETTEXT) -f $(EXTRACTFILES) -o $(EN) 2>/dev/null
	$(XGETTEXT) -f $(EXTRACTFILES) -o $(FR) 2>/dev/null

dev:
	$(CARTON) morbo $(ERT) --listen http://0.0.0.0:3000 --watch lib/ --watch script/ --watch themes/ --watch ethercalc_revision_tool.conf

devlog:
	multitail log/development.log

prod:
	$(CARTON) hypnotoad -f $(ERT)
