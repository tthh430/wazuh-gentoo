# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Wazuh Manager"
HOMEPAGE="https://wazuh.com"
SRC_URI="https://packages.wazuh.com/4.x/yum/${P}-1.x86_64.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="=app-misc/filebeat-oss-7.10.2
app-arch/rpm2targz"
RDEPEND="${DEPEND}"
BDEPEND=""

QA_PREBUILT="var/ossec/*
usr/lib/*
etc/rc.d/init.d/wazuh-manager"

S="${WORKDIR}"

src_install(){
	cp -pPR "${S}"/var "${D}"/ || die "Failed to copy files"

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

	# Create wazuh-manager user
	WM_USER="wazuh-manager"
	if [[ $(getent passwd "${WM_USER}" | grep -c "${WM_USER}") -eq 0 ]]; then
        einfo "${WM_USER} user does not exist"
        einfo "Creating ${WM_USER} user"
        useradd -d /dev/null -c "Wazuh Manager user" -M -r -U -s /sbin/nologin "${WM_USER}" > /dev/null

        if  [[ $(getent passwd ${WM_USER} | grep -c "${WM_USER}") -eq 1 ]]; then
            eeinfo "${WM_USER} user  created"
        else
            eerror "Error during ${WM_USER} user creation"
			exit 1
        fi
	else
		einfo "${WM_USER} user already exist. Skip"
    fi

	# Change owner of important directories to wazuh-manager user
    einfo "Change owner of /usr/share/wazuh-indexer to ${WM_USER}"
    chown -R "${WM_USER}":"${WM_USER}" /var/ossec

	# Start wazuh-manager service
    einfo
    einfo "Start wazuh-manager service"
    einfo 
    /etc/init.d/wazuh-manager start

    read -p "Would you like to start wazuh-manager service at boot ? [y/n] " start_at_boot

    if [[ -z "${start_at_boot}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
    fi 

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add wazuh-manager
    fi
}
