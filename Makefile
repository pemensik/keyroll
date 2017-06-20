
SUDO=		sudo
LATEST_KEY=	http://keyroll.systems/current.key
ROOT_KEY=	keyroll-systems-root.key
ROOT_ZONE=	keyroll-systems-root.zone
NAMED_KEYS=	named-keys.conf
UNBOUND_CONF=   unbound-rh.conf

NAMED_DEST=	/var/tmp/keyroll-named
UNBOUND_DEST=	/var/tmp/keyroll-unbound

NAMED=		/usr/local/sbin/named
UNBOUND=	/usr/local/sbin/unbound

MANAGED_KEYS_DIR=/var/named/dynamic

BAK_SUFFIX=     .keyroll

NAMED_RPM_ZONE= /var/named/named.ca
NAMED_RPM_KEYS=  /etc/named.root.key
UNBOUND_RPM_ZONE=/etc/unbound/$(ROOT_ZONE)
UNBOUND_RPM_KEYS=/var/lib/unbound/root.key
UNBOUND_RPM_CONF=/etc/unbound/conf.d/unbound-rh.conf

all:

fetch:
	curl -o $(ROOT_KEY) $(LATEST_KEY)

$(ROOT_KEY): fetch

$(NAMED_KEYS): $(ROOT_KEY)
	perl managed-keys.pl < $(ROOT_KEY) > $@

install: install-named-conf install-unbound-conf

install-rpm: install-named-rpm install-unbound-rpm

clean:
	rm -f $(ROOT_KEY) $(NAMED_KEYS)
	rm -fr $(NAMED_DEST)
	rm -fr $(UNBOUND_DEST)
	

$(NAMED_RPM_ZONE)$(BAK_SUFFIX):
	$(SUDO) mv $(NAMED_RPM_ZONE) $(NAMED_RPM_ZONE)$(BAK_SUFFIX)

$(NAMED_RPM_ZONE): $(ROOT_ZONE) $(NAMED_RPM_ZONE)$(BAK_SUFFIX)
	$(SUDO) install -m 644 $(ROOT_ZONE) $(NAMED_RPM_ZONE)

$(NAMED_RPM_KEYS)$(BAK_SUFFIX):
	$(SUDO) mv $(NAMED_RPM_KEYS) $(NAMED_RPM_KEYS)$(BAK_SUFFIX)

$(NAMED_RPM_KEYS): $(NAMED_KEYS) $(NAMED_RPM_KEYS)$(BAK_SUFFIX)
	$(SUDO) install -m 644 $(NAMED_KEYS) $(NAMED_RPM_KEYS)

install-named-rpm: $(NAMED_RPM_ZONE) $(NAMED_RPM_KEYS)

uninstall-named-rpm: $(NAMED_RPM_ZONE)$(BAK_SUFFIX) $(NAMED_RPM_KEYS)$(BAK_SUFFIX)
	$(SUDO) mv $(NAMED_RPM_ZONE)$(BAK_SUFFIX) $(NAMED_RPM_ZONE)
	$(SUDO) mv $(NAMED_RPM_KEYS)$(BAK_SUFFIX) $(NAMED_RPM_KEYS)

install-named-conf: $(NAMED_DEST)/$(ROOT_ZONE) $(NAMED_DEST)/$(NAMED_KEYS)
	
$(NAMED_DEST)/$(ROOT_ZONE): $(ROOT_ZONE)
	install -d $(NAMED_DEST)
	install -m 444 $(ROOT_ZONE) $(NAMED_DEST)

$(NAMED_DEST)/$(NAMED_KEYS): $(NAMED_KEYS)
	install -d $(NAMED_DEST)
	install -m 644 $(NAMED_KEYS) $(NAMED_DEST)/keys.conf

test-named: $(NAMED_DEST)/$(ROOT_ZONE) $(NAMED_DEST)/$(NAMED_KEYS)
	$(SUDO) $(NAMED) -g -c named.conf
	
clean-named:
	$(SUDO) rm -f ${MANAGED_KEYS_DIR}/*.mkeys{,.jnl} ${MANAGED_KEYS_DIR}/managed-keys.bind


install-unbound-conf: $(UNBOUND_DEST)/$(ROOT_ZONE) $(UNBOUND_DEST)/$(ROOT_KEY)

install-unbound-rpm: $(UNBOUND_RPM_ZONE) $(UNBOUND_RPM_KEYS)$(BAK_SUFFIX) $(UNBOUND_RPM_CONF)

uninstall-unbound-rpm: $(UNBOUND_RPM_ZONE) $(UNBOUND_RPM_KEYS)$(BAK_SUFFIX) $(UNBOUND_RPM_CONF)
	$(SUDO) mv $(UNBOUND_RPM_KEYS)$(BAK_SUFFIX) $(UNBOUND_RPM_KEYS)
	$(SUDO) rm -f $(UNBOUND_RPM_ZONE) $(UNBOUND_RPM_CONF)

$(UNBOUND_RPM_CONF): $(UNBOUND_CONF)
	$(SUDO) install -m 644 $(UNBOUND_CONF) $(UNBOUND_RPM_CONF)

$(UNBOUND_RPM_ZONE): $(ROOT_ZONE)
	$(SUDO) install -m 644 $(ROOT_ZONE) $(UNOBUND_RPM_ZONE)

$(UNBOUND_RPM_KEYS)$(BAK_SUFFIX): $(ROOT_KEY)
	$(SUDO) mv $(UNBOUND_RPM_KEYS) $(UNBOUND_RPM_KEYS)$(BAK_SUFFIX)
	$(SUDO) install -o unbound -g unbound -m 644 -Z system_u:object_r:named_cache_t $(ROOT_KEY) $(UNBOUND_RPM_KEYS)

$(UNBOUND_DEST)/$(ROOT_ZONE): $(ROOT_ZONE)	
	install -d $(UNBOUND_DEST)
	install -m 444 $(ROOT_ZONE) $(UNBOUND_DEST)

$(UNBOUND_DEST)/$(ROOT_KEY): $(ROOT_KEY)
	install -d $(UNBOUND_DEST)
	install -m 644 $(ROOT_KEY) $(UNBOUND_DEST)

test-unbound: $(UNBOUND_DEST)/$(ROOT_ZONE) $(UNBOUND_DEST)/$(ROOT_KEY)
	$(SUDO) $(UNBOUND) -dv -c unbound.conf
