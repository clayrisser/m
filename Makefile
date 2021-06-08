.PHONY: sudo
	@sudo true

.PHONY: install
install: sudo
	@sudo install m.sh /usr/local/bin/m

.PHONY: uninstall
uninstall:
	@rm -f /usr/local/bin/m
