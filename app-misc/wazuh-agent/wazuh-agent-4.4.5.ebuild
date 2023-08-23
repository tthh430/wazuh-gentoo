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

DEPEND="app-arch/rpm2targz"
RDEPEND="${DEPEND}"
BDEPEND=""

S="${WORKDIR}"

QA_PREBUILT="var/ossec/*
usr/lib/*
etc/rc.d/init.d/wazuh-agent"

src_install(){
	cp -pPR "${S}"/var "${D}"/ || die "Failed to copy files"

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
	WA_USER="wazuh-agent"
	if [[ $(getent passwd "${WA_USER}" | grep -c "${WA_USER}") -eq 0 ]]; then
        einfo "${WA_USER} user does not exist"
        einfo "Creating ${WA_USER} user"
        useradd -d /dev/null -c "Wazuh Agent user" -M -r -U -s /sbin/nologin "${WA_USER}" > /dev/null

        [[ $(getent passwd ${WA_USER} | grep -c "${WA_USER}") -eq 1 ]] || die "Failed to create ${WA_USER}"

	else
		einfo "${WA_USER} user already exist. Skip"
    fi

	# Change owner of important directories to wazuh-agent user
    einfo "Change owner of /var/ossec to ${WA_USER}"
    chown -R "${WA_USER}":"${WA_USER}" /var/ossec

	# Start wazuh-agent service
    einfo
    einfo "Start wazuh-agent service"
    einfo 
    /etc/init.d/wazuh-agent start

    read -p "Would you like to start wazuh-agent service at boot ? [y/n] " start_at_boot

    [[ -z "${start_at_boot}" ]] || die "Empty value not allowed"

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add wazuh-agent
    fi
}