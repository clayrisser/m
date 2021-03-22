.PHONY: install
install:
	@install m.sh /usr/local/bin/m

.PHONY: uninstall
uninstall:
	@rm -f /usr/local/bin/m

.PHONY: reinstall
reinstall: uninstall install
