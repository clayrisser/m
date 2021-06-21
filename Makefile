export MAKE_CACHE := $(shell pwd)/.make
export PARENT := true
include blackmagic.mk

CHROOT := sudo chroot .chroot
DEBFILE := m_0.1.0_amd64.deb
CODENAME := $(shell cat /etc/os-release | grep -E "^VERSION=" | \
	sed 's|^.*(||g' | sed 's|)"$$||g')

ifeq ($(CODENAME),)
	CODENAME := sid
endif

all: package

.PHONY: codename
codename:
	@echo $(CODENAME)

.PHONY: changelog
changelog: .chglog.yml
	@chglog init

.chglog.yml:
	@chglog config

.PHONY: package
package: package-rpm package-deb

.PHONY: package-rpm
package-rpm:
	@nfpm pkg --packager rpm --target .

.PHONY: package-deb
package-deb:
	@nfpm pkg --packager deb --target .

.PHONY: sudo
sudo:
	@sudo true

.PHONY: debootstrap
debootstrap: sudo .chroot/bin/bash
.chroot/bin/bash:
	@mkdir -p .chroot
	-@sudo debootstrap $(CODENAME) .chroot

.PHONY: chroot
chroot: sudo debootstrap
	@$(CHROOT)

.PHONY: clean
clean:
	-@sudo $(GIT) clean -fXd \
		-e .chroot \
		-e .chroot/ \
		-e .chroot/**/* \
		-e /.chroot \
		-e /.chroot/**/*

.PHONY: purge
purge: sudo clean
	-@sudo rm -rf .chroot $(NOFAIL)
	-@sudo $(GIT) clean -fXd

.PHONY: deps
deps: sudo
	@sudo apt install -y $(shell cat deps.list)

%.deb: package-deb

.PHONY: test
test: $(DEBFILE) .chroot/bin/bash
	@cp $< .chroot/tmp
	-@$(CHROOT) dpkg -i tmp/$<
	@$(CHROOT) apt install -y -f
	@$(CHROOT) dpkg -i tmp/$<
	@[ "$$($(CHROOT) which m)" = "/usr/bin/local/m" ] || (echo TESTS FAILED >&2 && exit 1)
	@echo TESTS PASSED

.PHONY: install
install: sudo
	@sudo mkdir -p /usr/local/share/zsh/site-functions
	@sudo cp _m.sh /usr/local/share/zsh/site-functions/_m
	@sudo install m.sh /usr/local/bin/m
	@echo uninstalled

.PHONY: uninstall
uninstall: sudo
	@sudo rm -f \
		/usr/local/share/zsh/site-functions/_m \
		/usr/local/bin/m
	@echo installed

.PHONY: reinstall
reinstall: uninstall install
	@echo reinstalled

-include $(patsubst %,$(_ACTIONS)/%,$(ACTIONS))

+%:
	@$(MAKE) -e -s $(shell echo $@ | $(SED) 's/^\+//g')

%: ;

CACHE_ENVS +=
