# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Wazuh Manager"
HOMEPAGE="https://wazuh.com"
SRC_URI="https://packages.wazuh.com/4.x/yum/${P}-x86_64.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

QA_PREBUILT="etc/filebeat/*
etc/init.d/filebeat
usr/share/filebeat/*"

S="${WORKDIR}"

src_install(){
	cp -pPR "${S}"/etc "${D}"/ || die "Failed to copy files"
	cp -pPR "${S}"/usr "${D}"/ || die "Failed to copy files"

	newinitd "${FILESDIR}"/filebeat-oss-initd filebeat-oss
	newconfd "${FILESDIR}"/filebeat-oss-confd filebeat-oss
}

pkg_postinst() {
	elog "To finish the Filebeat-oss install, you need to follow the following step:"
	elog
	elog "\t- Initialiaze the environment"
	elog "\t- Deploy certificates"
	elog "\t- Start the service"
	elog "\t- Test filebeat"
	elog

	elog "Execute the following command to initializa environment:"
	elog
	elog "\t# emerge --config \"=${CATEGORY}/${PF}\""
	elog

	elog "Start the service"
	elog
	elog "\t# /etc/init.d/filebeat-oss start"
	elog "To start the service at boot"
	elog "\t# rc-update add filebeat-oss"
	elog

	elog "To test filebeat installation, run the following command:"
	elog "\t# sudo -u <filebeat-oss user> /usr/share/filebeat/bin/filebeat test output"
}

pkg_config() {

	# Create filebeat-oss user
	WM_USER="filebeat-oss"
	if [[ $(getent passwd "${WM_USER}" | grep -c "${WM_USER}") -eq 0 ]]; then
        einfo "${WM_USER} user does not exist"
        einfo "Creating ${WM_USER} user"
        useradd -d /dev/null -c "Filebeat-oss user" -M -r -U -s /sbin/nologin "${WM_USER}" > /dev/null

        if  [[ $(getent passwd ${WM_USER} | grep -c "${WM_USER}") -eq 1 ]]; then
            eeinfo "${WM_USER} user created"
        else
            eerror "Error during ${WM_USER} user creation"
        fi
	else
		einfo "${WM_USER} user already exist. Skip"
    fi

	einfo "Set the right owner to the filebeat bin"
	chown "${WM_USER}:${WM_USER} /usr/bin/filebeat"

	einfo "Set the right owner to the filebeat directory config"
	chown -R "${WM_USER}:${WM_USER} /etc/filebeat"

	einfo "Set the right owner to the filebeat home directory"
	chown -R "${WM_USER}:${WM_USER} /usr/share/filebeat"

	einfo "Download preconfigured filebeat configuration file"
	curl -so /etc/filebeat/filebeat.yml https://packages.wazuh.com/4.4/tpl/wazuh/filebeat/filebeat.yml

	einfo "Create a Filebeat keystore to securely store authentication credentials"
	sudo -u "${WM_USER}" /usr/share/filebeat/bin/filebeat keystore create

	einfo "Add the default credentials to the keystore"
	einfo "\tDefault username : admin"
	einfo "\tDefault password : admin"
	echo admin | sudo -u "${WM_USER}" /usr/share/filebeat/bin/filebeat add username --stdin --force
	echo admin | sudo -u "${WM_USER}" /usr/share/filebeat/bin/filebeat add password --stdin --force

	einfo "Download the alerts template for the Wazuh indexer"
	curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/4.4/extensions/elasticsearch/7.x.wazuh-template.json
	chown -R "${WM_USER}:${WM_USER} /etc/filebeat"

	einfo "Install the Wazuh module for filebeat"
	curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.2.tar.gz | tar -xvz -C /usr/share/filebeat/module
	chown -R "${WM_USER}:${WM_USER} /usr/share/filebeat"
}
