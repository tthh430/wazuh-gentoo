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

DEPEND="=app-misc/wazuh-manager-4.4.5
app-arch/rpm2targz"
RDEPEND="${DEPEND}"
BDEPEND=""

QA_PREBUILT="etc/filebeat/*
etc/init.d/filebeat
usr/share/filebeat/*"

S="${WORKDIR}"

src_install(){
	cp -pPR "${S}"/etc "${D}"/ || die "Failed to copy files"
	cp -pPR "${S}"/usr "${D}"/ || die "Failed to copy files"

	keepdir /var/lib/filebeat
	keepdir /var/log/filebeat

	newinitd "${FILESDIR}"/filebeat-oss-initd filebeat-oss
	newconfd "${FILESDIR}"/filebeat-oss-confd filebeat-oss

	curl -so "${D}"/etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/4.4/extensions/elasticsearch/7.x/wazuh-template.json
	curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.2.tar.gz | tar -xvz -C "${D}"/usr/share/filebeat/module


}

pkg_postinst() {
	elog "To finish the Filebeat-oss install, you need to follow the following step :"
	elog
	elog "\t- Configure Filebeat"
	elog "\t- Test filebeat"
	elog

	elog "Execute the following command to initializa environment:"
	elog
	elog "\t# emerge --config \"=${CATEGORY}/${PF}\""
	elog
}

pkg_config() {

	# Create filebeat-oss user
	#FB_USER="filebeat-oss"
	FB_USER="root"

	read -p "Wazuh indexer IP or hostname : " wazuh_indexer

	# Write filebeat configuration file
	filebeat_configuration_path="/etc/filebeat/filebeat.yml"

	echo -e "output.elasticsearch:" > ${filebeat_configuration_path}
	echo -e "  hosts: [\"${wazuh_indexer}:9200\"]" >> ${filebeat_configuration_path}
	echo -e "  protocol: https" >> ${filebeat_configuration_path}
	echo -e "  username: \${username}" >> ${filebeat_configuration_path}
	echo -e "  password: \${password}" >> ${filebeat_configuration_path}
	echo -e "  ssl.certificate_authorities:" >> ${filebeat_configuration_path}
	echo -e "    - /etc/filebeat/certs/root-ca.pem" >> ${filebeat_configuration_path}
	echo -e "  ssl.certificate: \"/etc/filebeat/certs/filebeat.pem\"" >> ${filebeat_configuration_path}
	echo -e "  ssl.key: \"/etc/filebeat/certs/filebeat-key.pem\"" >> ${filebeat_configuration_path}
	echo -e "setup.template.json.enabled: true" >> ${filebeat_configuration_path}
	echo -e "setup.template.json.path: '/etc/filebeat/wazuh-template.json'" >> ${filebeat_configuration_path}
	echo -e "setup.template.json.name: 'wazuh'" >> ${filebeat_configuration_path}
	echo -e "setup.ilm.overwrite: true" >> ${filebeat_configuration_path}
	echo -e "setup.ilm.enabled: false" >> ${filebeat_configuration_path}
	echo -e "" >> ${filebeat_configuration_path}
	echo -e "filebeat.modules:" >> ${filebeat_configuration_path}
	echo -e "  - module: wazuh" >> ${filebeat_configuration_path}
	echo -e "    alerts:" >> ${filebeat_configuration_path}
	echo -e "      enabled: true" >> ${filebeat_configuration_path}
	echo -e "    archives:" >> ${filebeat_configuration_path}
	echo -e "      enabled: false" >> ${filebeat_configuration_path}
	echo -e "" >> ${filebeat_configuration_path}
	echo -e "logging.level: info" >> ${filebeat_configuration_path}
	echo -e "logging.to_files: true" >> ${filebeat_configuration_path}
	echo -e "logging.files:" >> ${filebeat_configuration_path}
	echo -e "  path: /var/log/filebeat" >> ${filebeat_configuration_path}
	echo -e "  name: filebeat" >> ${filebeat_configuration_path}
	echo -e "  keepfiles: 7" >> ${filebeat_configuration_path}
	echo -e "  permissions: 0644" >> ${filebeat_configuration_path}
	echo -e "" >> ${filebeat_configuration_path}
	echo -e "logging.metrics.enabled: false" >> ${filebeat_configuration_path}
	echo -e "" >> ${filebeat_configuration_path}
	echo -e "seccomp:" >> ${filebeat_configuration_path}
	echo -e "  default_action: allow" >> ${filebeat_configuration_path}
	echo -e "  syscalls:" >> ${filebeat_configuration_path}
	echo -e "  - action: allow" >> ${filebeat_configuration_path}
	echo -e "    names:" >> ${filebeat_configuration_path}
	echo -e "    - rseq" >> ${filebeat_configuration_path}

    # Change owner of important directories to filebeat-oss user
	einfo "Set the right owner to the filebeat bin"
	chown ${FB_USER}:${FB_USER} /usr/bin/filebeat

	einfo "Set the right owner to the filebeat directory config"
	chown -R ${FB_USER}:${FB_USER} /etc/filebeat

	einfo "Set the right owner to the filebeat home directory"
	chown -R ${FB_USER}:${FB_USER} /usr/share/filebeat

	einfo "Set the right owner to the filebeat data directory"
	chown -R ${FB_USER}:${FB_USER} /var/lib/filebeat

	einfo "Set the right owner to the filebeat logs directory"
	chown -R ${FB_USER}:${FB_USER} /var/log/filebeat

	einfo "Create a Filebeat keystore to securely store authentication credentials"
	/usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml keystore --path.config /etc/filebeat --path.home /usr/share/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat create

	einfo "Add the default credentials to the keystore"
	einfo "\tDefault username : admin"
	einfo "\tDefault password : admin"
	echo admin | /usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml keystore --path.config /etc/filebeat --path.home /usr/share/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat add username --stdin --force
	echo admin | /usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml keystore --path.config /etc/filebeat --path.home /usr/share/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat add password --stdin --force

	einfo "Download the alerts template for the Wazuh indexer"
	chown -R ${FB_USER}:${FB_USER} /etc/filebeat
	chmod go+r /etc/filebeat/wazuh-template.json

	einfo "Install the Wazuh module for filebeat"
	chown -R ${FB_USER}:${FB_USER} /usr/share/filebeat

	# Deploy certificates
	einfo "Deploying certificates"
	einfo

	einfo "Node name must match name in certificates"
	read -p "Node name : " node_name

	if [[ -z ${node_name} ]]; then
        eerror "Empty value not allowed !"
		exit 1
	fi

	read -p "Certificates tar file path on node : " certificates_path

	if [[ -z ${certificates_path} ]]; then
        eerror "Empty value not allowed !"
		exit 1
	fi

	if [[ ! -s "${certificates_path}" ]]; then
		eerror "${certificates_path} does not exist or is empty"
		exit 1
	fi 

	export NODE_NAME="${node_name}"
    mkdir -p /etc/filebeat/certs
	tar -xf "${certificates_path}" -C /etc/filebeat/certs/ ./${NODE_NAME}.pem ./${NODE_NAME}-key.pem ./root-ca.pem
	mv -n /etc/filebeat/certs/${NODE_NAME}.pem /etc/filebeat/certs/filebeat.pem
	mv -n /etc/filebeat/certs/${NODE_NAME}-key.pem /etc/filebeat/certs/filebeat-key.pem
	chmod 500 /etc/filebeat/certs
	chmod 400 /etc/filebeat/certs/*
	chown -R ${FB_USER}:${FB_USER} /etc/filebeat/certs

	# Start Filebeat service
	einfo
	einfo "Start Filebeat service"
	einfo
	/etc/init.d/filebeat-oss start

	read -p "Would you like to start Filebeat service at boot ? [y/n] " start_at_boot
	
	if [[ -z "${start_at_boot}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
    fi 

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add filebeat-oss
    fi

	# Test installation
	einfo "To test the installation run the following command :"
	einfo "/usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml test --path.config /etc/filebeat --path.home /usr/share/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat config"
	einfo "/usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml test --path.config /etc/filebeat --path.home /usr/share/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat output"
}
