.PHONY: install
install:
	@install m.sh -T /usr/sbin/m

.PHONY: uninstall
uninstall:
	@rm -f /usr/sbin/m

.PHONY: reinstall
reinstall: uninstall install
