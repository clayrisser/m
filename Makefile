.PHONY: install
install: sudo
	@sudo mkdir -p /usr/local/share/zsh/site-functions
	@sudo cp _m.sh /usr/local/share/zsh/site-functions/_m
	@sudo install m.sh /usr/local/bin/m

.PHONY: uninstall
uninstall: sudo
	@sudo rm -f \
		/usr/local/share/zsh/site-functions/_m \
		/usr/local/bin/m

.PHONY: reinstall
reinstall: uninstall install

.PHONY: sudo
	@sudo true
