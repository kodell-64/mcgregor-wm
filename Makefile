PREFIX  = /usr/local
CC      = cc
CFLAGS  = -std=c99 -O2 -Wall -Wextra
LDLIBS  = -lX11 -lXinerama
VERSION = 1.1

all: mcgregor-wm

mcgregor-wm: mcgregor-wm.c
	$(CC) $(CFLAGS) -o $@ mcgregor-wm.c $(LDFLAGS) $(LDLIBS)

install: mcgregor-wm
	install -Dm755 mcgregor-wm $(DESTDIR)$(PREFIX)/bin/mcgregor-wm
	install -Dm644 mcgregor-wm.1 $(DESTDIR)$(PREFIX)/share/man/man1/mcgregor-wm.1
	install -Dm644 mcgregor-wm.desktop $(DESTDIR)/usr/share/xsessions/mcgregor-wm.desktop

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/mcgregor-wm \
	      $(DESTDIR)$(PREFIX)/share/man/man1/mcgregor-wm.1 \
	      $(DESTDIR)/usr/share/xsessions/mcgregor-wm.desktop

# Build a .deb you can install with apt (needs dpkg-deb, which Debian has).
deb: mcgregor-wm
	rm -rf pkg
	$(MAKE) install DESTDIR=$(CURDIR)/pkg PREFIX=/usr
	strip pkg/usr/bin/mcgregor-wm
	gzip -9n pkg/usr/share/man/man1/mcgregor-wm.1
	mkdir -p pkg/DEBIAN
	printf 'Package: mcgregor-wm\nVersion: $(VERSION)\nArchitecture: %s\nMaintainer: you <you@localhost>\nDepends: libx11-6, libxinerama1, libc6, xfonts-base\nRecommends: x11-xserver-utils\nProvides: x-window-manager\nSection: x11\nPriority: optional\nDescription: extremely minimal Blackbox-style window manager\n Title-bar frames, multiple desktops, Alt+Tab in most-recently-used\n order, and new windows never steal the keyboard focus.\n' \
	    "$$(dpkg --print-architecture)" > pkg/DEBIAN/control
	printf '#!/bin/sh\nset -e\nif [ "$$1" = configure ]; then update-alternatives --install /usr/bin/x-window-manager x-window-manager /usr/bin/mcgregor-wm 20; fi\n' > pkg/DEBIAN/postinst
	printf '#!/bin/sh\nset -e\nif [ "$$1" = remove ]; then update-alternatives --remove x-window-manager /usr/bin/mcgregor-wm; fi\n' > pkg/DEBIAN/prerm
	chmod 755 pkg/DEBIAN/postinst pkg/DEBIAN/prerm
	dpkg-deb --root-owner-group --build pkg mcgregor-wm_$(VERSION)_$$(dpkg --print-architecture).deb

clean:
	rm -rf mcgregor-wm pkg *.deb

.PHONY: all install uninstall deb clean
