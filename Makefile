SHELL := /bin/bash

.PHONY: install status doctor backup update uninstall purge deb

install:
	sudo bash scripts/install.sh

status:
	bash scripts/status.sh

doctor:
	bash scripts/doctor.sh

backup:
	sudo bash scripts/backup.sh

update:
	sudo bash scripts/update.sh

uninstall:
	sudo bash scripts/uninstall.sh

purge:
	sudo bash scripts/uninstall.sh --purge

deb:
	bash packaging/build-deb.sh
