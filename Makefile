ifndef DESTDIR
DESTDIR=/usr/
endif
ifndef CONFDIR
CONFDIR=/etc
endif

install:
	mkdir -p /usr/lib/kvc/ && mkdir -p /etc/kvc/
	install -v -m 644 iavf-kmod-lib.sh $(DESTDIR)/lib/kvc/
	install -v -m 644 iavf-kmod.conf $(CONFDIR)/kvc/
	install -v -m 755 iavf-kmod-wrapper.sh $(DESTDIR)/lib/kvc/
