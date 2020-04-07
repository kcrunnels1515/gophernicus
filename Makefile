##
## Gophernicus server Makefile
##

#
# Variables and default configuration
#
NAME     = gophernicus
PACKAGE  = $(NAME)
BINARY   = in.$(NAME)
VERSION  = `./version`
CODENAME = Prison Edition
AUTHOR   = Kim Holviala
EMAIL    = kimholviala@fastmail.com
STARTED  = 2009

SOURCES = $(NAME).c file.c menu.c string.c platform.c session.c options.c
HEADERS = functions.h files.h
OBJECTS = $(SOURCES:.c=.o)
DOCS    = LICENSE README INSTALL TODO ChangeLog README.Gophermap gophertag

INSTALL = PATH=$$PATH:/usr/sbin ./install-sh -o 0 -g 0
DESTDIR = /usr
OSXDEST = /usr/local
SBINDIR = $(DESTDIR)/sbin
DOCDIR  = $(DESTDIR)/share/doc/$(PACKAGE)

ROOT    = /var/gopher
OSXROOT = /Library/GopherServer
WRTROOT = /gopher
MAP     = gophermap

INETD   = /etc/inetd.conf
XINETD  = /etc/xinetd.d
LAUNCHD = /Library/LaunchDaemons
PLIST   = org.$(NAME).server.plist
NET_SRV = /boot/common/settings/network/services
SYSTEMD = /lib/systemd/system /usr/lib/systemd/system
HAS_STD = /run/systemd/system
SYSCONF = /etc/sysconfig
DEFAULT = /etc/default

CC      = gcc
HOSTCC	= $(CC)
CFLAGS  = -O2 -Wall
LDFLAGS = 

#IPCRM   = /usr/bin/ipcrm

#
# Platform support, compatible with both BSD and GNU make
#
all:
	if [ -f "/usr/include/tcpd.h" ]; then $(MAKE) withwrap; else $(MAKE) $(BINARY); fi; 

generic: $(BINARY)

withwrap:
	$(MAKE) EXTRA_CFLAGS="-DHAVE_LIBWRAP" EXTRA_LIBS="-lwrap" $(BINARY)


#
# Special targets
#
deb:
	printf "$(PACKAGE) ($(VERSION)) unstable; urgency=low\n\n  * Automatically generated changelog\n\n" > debian/changelog
	printf " -- $(AUTHOR) <$(EMAIL)>  %s\n" "`LC_ALL=POSIX date "+%a, %d %b %Y %H:%M:%S %z"`" >> debian/changelog
	dpkg-buildpackage -rfakeroot -uc -us

ChangeLog:
	if [ -d .git ]; then \
		(./git2changelog > ChangeLog; \
		cat changelog.old >> ChangeLog); \
	else true; fi

.PHONY: ChangeLog


#
# Building
#
$(NAME).c: $(NAME).h $(HEADERS)
	
$(BINARY): $(OBJECTS)
	$(CC) $(LDFLAGS) $(EXTRA_LDFLAGS) $(OBJECTS) $(EXTRA_LIBS) -o $@

.c.o:
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -DVERSION="\"$(VERSION)\"" -DCODENAME="\"$(CODENAME)\"" -DDEFAULT_ROOT="\"$(ROOT)\"" $< -o $@


headers: $(HEADERS)
	@echo

functions.h:
	echo "/* Automatically generated function definitions */" > $@
	echo >> $@
	grep -h "^[a-z]" $(SOURCES) | \
		grep -v "int main" | \
		grep -v "strlc" | \
		grep -v "[a-z]:" | \
		sed -e "s/ =.*$$//" -e "s/ *$$/;/" >> $@
	@echo

bin2c: bin2c.c
	$(HOSTCC) bin2c.c -o $@
	@echo

files.h: bin2c
	sed -n -e "1,/^ $$/p" README > README.options
	./bin2c -0 -n README README.options > $@
	./bin2c -0 LICENSE >> $@
	./bin2c -n ERROR_GIF error.gif >> $@
	@echo


#
# Cleanup after building
#
clean: clean-build clean-deb

clean-build:
	rm -f $(BINARY) $(OBJECTS) $(HEADERS) README.options bin2c

clean-deb:
	if [ -d debian/$(PACKAGE) ]; then fakeroot debian/rules clean; fi

#clean-shm:
#	if [ -x $(IPCRM) ]; then $(IPCRM) -M `awk '/SHM_KEY/ { print $$3 }' $(NAME).h` || true; fi


#
# Install targets
#
install: ChangeLog #clean-shm
	$(MAKE) install-files install-docs install-root; 
	@if [ -d "$(HAS_STD)" ]; then $(MAKE) install-systemd install-done; \
	elif [ -d "$(XINETD)" ]; then $(MAKE) install-xinetd install-done; \
	elif [ -f "$(INETD)"  ]; then $(MAKE) install-inetd; fi

.PHONY: install

install-done:
	@echo
	@echo "======================================================================"
	@echo
	@echo "Gophernicus has now been succesfully installed. To try it out, launch"
	@echo "your favorite gopher browser and navigate to your gopher root."
	@echo
	@echo "Gopher URL...: gopher://`hostname`/"
	@for CONFFILE in /etc/sysconfig/gophernicus \
		/etc/default/gophernicus \
		/Library/LaunchDaemons/org.gophernicus.server.plist \
		/boot/common/settings/network/services \
		/lib/systemd/system/gophernicus\@.service \
		/etc/xinetd.d/gophernicus \
		/etc/inetd.conf; do \
			if [ -f $$CONFFILE ]; then echo "Configuration: $$CONFFILE"; break; fi; done;
	@echo
	@echo "======================================================================"
	@echo

install-files:
	mkdir -p $(SBINDIR)
	$(INSTALL) -s -m 755 $(BINARY) $(SBINDIR)
	@echo

install-docs:
	mkdir -p $(DOCDIR)
	$(INSTALL) -m 644 $(DOCS) $(DOCDIR)
	@echo

install-root:
	if [ ! -d "$(ROOT)" -o ! -f "$(ROOT)/$(MAP)" ]; then \
		mkdir -p $(ROOT); \
		$(INSTALL) -m 644 $(MAP) $(ROOT); \
		ln -s $(DOCDIR) $(ROOT)/docs; \
	fi
	@echo

install-inetd:
	@echo
	@echo "======================================================================"
	@echo
	@echo "Looks like your system has the traditional internet superserver inetd."
	@echo "Automatic installations aren't supported, so please add the following"
	@echo "line to the end of your /etc/inetd.conf and restart or kill -HUP the"
	@echo "inetd process."
	@echo
	@echo "gopher  stream  tcp  nowait  nobody  $(SBINDIR)/$(BINARY)  $(BINARY) -h `hostname`"
	@echo
	@echo "======================================================================"
	@echo

install-xinetd:
	if [ -d "$(XINETD)" -a ! -f "$(XINETD)/$(NAME)" ]; then \
		sed -e "s/@HOSTNAME@/`hostname`/g" $(NAME).xinetd > $(XINETD)/$(NAME); \
		[ -x /sbin/service ] && /sbin/service xinetd reload; \
	fi
	@echo

install-systemd:
	if [ -d "$(HAS_STD)" ]; then \
		if [ -d "$(SYSCONF)" -a ! -f "$(SYSCONF)/$(NAME)" ]; then \
			$(INSTALL) -m 644 $(NAME).env $(SYSCONF)/$(NAME); \
		fi; \
		if [ ! -d "$(SYSCONF)" -a -d "$(DEFAULT)" -a ! -f $(DEFAULT)/$(NAME) ]; then \
			$(INSTALL) -m 644 $(NAME).env $(DEFAULT)/$(NAME); \
		fi; \
		for DIR in $(SYSTEMD); do \
			if [ -d "$$DIR" ]; then \
				$(INSTALL) -m 644 $(NAME).socket $(NAME)\@.service $$DIR; \
				break; \
			fi; \
		done; \
		systemctl daemon-reload; \
		systemctl enable $(NAME).socket; \
		systemctl start $(NAME).socket; \
	fi
	@echo


# Self-signed keys

key:
	openssl req -newkey rsa:4096 -nodes -sha512 -x509 -days 3650 -nodes \
		-subj "/C=UK/ST=London/O=Gophernicus/OU=gopherd/CN=localhost" \
		-out gophernicus.pem -keyout gophernicus.key

key-install:
	$(INSTALL) -m 440 gophernicus.pem /etc/ssl/
	$(INSTALL) -m 400 gophernicus.key /etc/ssl/
	chown _gophernicus /etc/ssl/gophernicus.pem
	chown _gophernicus /etc/ssl/gophernicus.key

#
# Uninstall targets
#
uninstall: uninstall-xinetd uninstall-launchd uninstall-systemd
	rm -f $(SBINDIR)/$(BINARY)
	for DOC in $(DOCS); do rm -f $(DOCDIR)/$$DOC; done
	rmdir -p $(SBINDIR) $(DOCDIR) 2>/dev/null || true
	@echo

uninstall-xinetd:
	if grep -q $(BINARY) "$(XINETD)/gopher" 2>/dev/null; then \
		rm -f $(XINETD)/gopher; \
		[ -x /sbin/service ] && service xinetd reload; \
	fi
	@echo

uninstall-launchd:
	if [ -f $(LAUNCHD)/$(PLIST) ]; then \
		launchctl unload $(LAUNCHD)/$(PLIST); \
		rm -f $(LAUNCHD)/$(PLIST); \
	fi
	if [ -L $(ROOT) ]; then \
		rm -f $(ROOT); \
	fi
	@echo

uninstall-systemd:
	if [ -d "$(HAS_STD)" ]; then \
		for DIR in $(SYSTEMD); do \
			if [ -f "$$DIR/$(NAME).socket" ]; then \
				systemctl stop $(NAME).socket; \
				systemctl disable $(NAME).socket; \
				rm -f $$DIR/$(NAME).socket $$DIR/$(NAME)\@.service $(SYSCONF)/$(NAME) $(DEFAULT)/$(NAME); \
				systemctl daemon-reload; \
				break; \
			fi; \
		done; \
	fi
	@echo


#
# List all C defines
#
defines: functions.h files.h
	$(CC) -dM -E $(NAME).c


#
# LOC
#
loc:
	@wc -l *.c


#
# Fix copyright notes
#
copyright:
	sed -i .stupid -e "s/Copyright .c. 2.*$$/Copyright (c) $(STARTED)-`date +%Y` $(AUTHOR) <$(EMAIL)>/" *.c *.h LICENSE README debian/copyright
	sed -i .stupid -e "s/Maintainer: .*$$/Maintainer: $(AUTHOR) <$(EMAIL)>/" debian/control
	rm -f *.stupid debian/*.stupid