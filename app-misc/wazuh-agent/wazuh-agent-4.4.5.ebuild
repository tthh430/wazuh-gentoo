# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Wazuh Agent"
HOMEPAGE="https://wazuh.com"
SRC_URI="https://packages.wazuh.com/4.x/yum/${P}-1.x86_64.rpm"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"

DEPEND="app-arch/rpm2targz
acct-user/wazuh
acct-group/wazuh"
RDEPEND="${DEPEND}"
BDEPEND=""

S="${WORKDIR}"

QA_PREBUILT="var/ossec/*
usr/lib/*
etc/rc.d/init.d/wazuh-agent"

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

	newinitd "${FILESDIR}"/wazuh-agent-initd wazuh-agent
	newconfd "${FILESDIR}"/wazuh-agent-confd wazuh-agent
}

pkg_postinst() {
	elog "To finish the Wazuh Agent install, you need to follow the following step :"
	elog
	elog "\t- Configure Wazuh Agent"
	elog

	elog "Execute the following command to configure Wazuh Agent"
	elog
	elog "\t# emerge --config \"=${CATEGORY}/${PF}\""
	elog
}

pkg_config() {

	# Create wazuh-agent user
	WA_USER="wazuh"

	# Change owner of important directories to wazuh-agent user
    einfo "Change owner of /var/ossec to ${WA_USER}"
    chown -R ${WA_USER}:${WA_USER} /var/ossec

	read -p "Wazuh manager IP : " wazuh_manager_ip
	sed -i "s|MANAGER_IP|${wazuh_manager_ip}|g" /var/ossec/etc/ossec.conf

	# Start wazuh-agent service
    einfo
    einfo "Start wazuh-agent service"
    einfo 
    /etc/init.d/wazuh-agent start

    read -p "Would you like to start wazuh-agent service at boot ? [y/n] " start_at_boot

    [[ ! -z "${start_at_boot}" ]] || die "Empty value not allowed"

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add wazuh-agent
    fi
}