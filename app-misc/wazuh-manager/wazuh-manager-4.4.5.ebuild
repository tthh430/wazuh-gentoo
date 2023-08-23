# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Wazuh Manager"
HOMEPAGE="https://wazuh.com"
SRC_URI="https://packages.wazuh.com/4.x/yum/${P}-1.x86_64.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

DEPEND="acct-user/wazuh
acct-group/wazuh
app-arch/rpm2targz"
RDEPEND="${DEPEND}"
BDEPEND=""

QA_PREBUILT="var/ossec/*
usr/lib/*
etc/rc.d/init.d/wazuh-manager"

S="${WORKDIR}"

src_install(){
	cp -pPR "${S}"/var "${D}"/ || die "Failed to copy files"

	keepdir /var/ossec/var/run
	keepdir /var/ossec/logs/alerts
	keepdir /var/ossec/logs/api
	keepdir /var/ossec/logs/archives
	keepdir /var/ossec/logs/cluster
	keepdir /var/ossec/logs/firewall
	keepdir /var/ossec/logs/wazuh
	keepdir /var/ossec/ruleset/sca
	keepdir /var/ossec/api/configuration/ssl
	keepdir /var/ossec/api/configuration/security
	keepdir /var/ossec/queue/agentless
	keepdir /var/ossec/queue/alerts	
	keepdir /var/ossec/queue/cluster
	keepdir /var/ossec/queue/db
	keepdir /var/ossec/queue/diff
	keepdir /var/ossec/queue/fim/db
	keepdir /var/ossec/queue/fts
	keepdir /var/ossec/queue/logcollector
	keepdir /var/ossec/queue/rids
	keepdir /var/ossec/queue/sockets
	keepdir /var/ossec/queue/syslogcollector/db
	keepdir /var/ossec/queue/tasks
	keepdir /var/ossec/queue/vulnerabilities
	keepdir /var/ossec/backup/db
	keepdir /var/ossec/backup/agents
	keepdir /var/ossec/backup/shared
	keepdir /var/ossec/stats
	keepdir /var/ossec/tmp
	keepdir /var/ossec/var/download
	keepdir /var/ossec/var/multigroups
	keepdir /var/ossec/var/upgrades
	keepdir /var/ossec/var/wodles

	newinitd "${FILESDIR}"/wazuh-manager-initd wazuh-manager
	newconfd "${FILESDIR}"/wazuh-manager-confd wazuh-manager
}

pkg_postinst() {
	elog "To finish the Wazuh Manager install, you need to follow the following step:"
	elog
	elog "\t- Configure Wazuh Manager"
	elog

	elog "Execute the following command to configure Wazuh Manager"
	elog
	elog "\t# emerge --config \"=${CATEGORY}/${PF}\""
	elog
}

pkg_config() {

	# wazuh-manager user
	WM_USER="wazuh"

	# Generate sslmanager cert
	read -p "Wazuh manager IP : " wazuh_manager_ip

	[[ ! -z "${wazuh_manager_ip}" ]] || die "Empty value not allowed !"

	read -p "Wazuh manager hostname : " wazuh_manager_hostname

	[[ ! -z "${wazuh_manager_hostname}" ]] || die "Empty value not allowed !"

	mkdir -p /var/ossec/certs
	cd /var/ossec/certs

	openssl req -x509 -new -nodes -newkey rsa:4096 -keyout rootCA.key -out rootCA.pem -batch -subj "/C=US/ST=CA/O=Wazuh"

	echo -e "[req]" > /var/ossec/certs/req.conf
    echo -e "distinguished_name = req_distinguished_name" >> /var/ossec/certs/req.conf
    echo -e "req_extensions = req_ext" >> /var/ossec/certs/req.conf
    echo -e "prompt = no" >> /var/ossec/certs/req.conf
    echo -e "[req_distinguished_name]" >> /var/ossec/certs/req.conf
    echo -e "C = US" >> /var/ossec/certs/req.conf
    echo -e "CN = ${wazuh_manager_ip}" >> /var/ossec/certs/req.conf
    echo -e "[req_ext]" >> /var/ossec/certs/req.conf
    echo -e "subjectAltName = @alt_names" >> /var/ossec/certs/req.conf
    echo -e "[alt_names]" >> /var/ossec/certs/req.conf
    echo -e "DNS.1 = ${wazuh_manager_hostname}" >> /var/ossec/certs/req.conf

	openssl req -new -nodes -newkey rsa:4096 -keyout sslmanager.key -out sslmanager.csr -config req.conf

	openssl x509 -req -days 365 -in sslmanager.csr -CA rootCA.pem -CAkey rootCA.key -out sslmanager.cert -CAcreateserial -extfile req.conf -extensions req_ext

	cp sslmanager.cert sslmanager.key /var/ossec/etc

	# Change owner of important directories to wazuh-manager user
    einfo "Change owner of /usr/share/wazuh-indexer to ${WM_USER}"
    chown -R "${WM_USER}":"${WM_USER}" /var/ossec

	# Start wazuh-manager service
    einfo
    einfo "Start wazuh-manager service"
    einfo 
    /etc/init.d/wazuh-manager start

    read -p "Would you like to start wazuh-manager service at boot ? [y/n] " start_at_boot

    [[ ! -z "${start_at_boot}" ]] || die "Empty value not allowed !"

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add wazuh-manager
    fi
}
