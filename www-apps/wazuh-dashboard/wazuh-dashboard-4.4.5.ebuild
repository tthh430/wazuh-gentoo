# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Wazuh Dashboard"
HOMEPAGE="https://wazuh.com"
SRC_URI="https://packages.wazuh.com/4.x/yum/${P}-1.x86_64.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="sys-libs/libcap
app-arch/rpm2targz"

RDEPEND="${DEPEND}"
BDEPEND=""

QA_PREBUILT="usr/share/wazuh-dashboard/*
usr/*"

S="${WORKDIR}"

src_install(){
cp -pPR "${S}"/usr "${D}"/ || die "Failed to copy files"
cp -pPR "${S}"/etc "${D}"/ || die "Failed to copy files"

	newinitd "${FILESDIR}"/wazuh-dashboard-initd wazuh-dashboard
	newconfd "${FILESDIR}"/wazuh-dashboard-confd wazuh-dashboard
}

pkg_postinst() {
	elog "To finish the Wazuh Dashboard install, you need to follow the following step:"
	elog
	elog "\t- Configure Wazuh Dashboard"
	elog

	elog "Execute the following command to initialize the environment:"
	elog
	elog "\t# emerge --config \"=${CATEGORY}/${PF}\""
	elog
}

pkg_config() {

	# Create wazuh-dashboard user
	WD_USER="wazuh-dashboard"
	if [[ $(getent passwd "${WD_USER}" | grep -c "${WD_USER}") -eq 0 ]]; then
        einfo "${WD_USER} user does not exist"
        einfo "Creating ${WD_USER} user"
        useradd -d /dev/null -c "Wazuh Dashboard user" -M -r -U -s /sbin/nologin "${WD_USER}" > /dev/null

        if  [[ $(getent passwd ${WD_USER} | grep -c "${WD_USER}") -eq 1 ]]; then
            eeinfo "${WD_USER} user  created"
        else
            eerror "Error during ${WD_USER} user creation"
			exit 1
        fi
	else
		einfo "${WD_USER} user already exist. Skip"
    fi

	# Configuring Wazuh dashboard
	read -p "Wazuh dashboard node name or IP : " wazuh_dashboard

	if [[ -z "${wazuh_dashboard}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
	fi

	read -p "Wazuh indexer node name or IP : " wazuh_indexer

	if [[ -z "${wazuh_indexer}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
	fi

	# Write Wazuh dashboard configuration file
	wazuh_dashboard_configuration_path="/etc/wazuh-dashboard/opensearch_dashboards.yml"
	
	echo -e "server.host: ${wazuh_dashboard}" > ${wazuh_dashboard_configuration_path}
	echo -e "server.port: 443" >> ${wazuh_dashboard_configuration_path}
	echo -e "opensearch.hosts: https://${wazuh_indexer}:9200" >> ${wazuh_dashboard_configuration_path}
	echo -e "opensearch.ssl.verificationMode: certificate" >> ${wazuh_dashboard_configuration_path}
	echo -e "#opensearch.username:" >> ${wazuh_dashboard_configuration_path}
	echo -e "#opensearch.password:" >> ${wazuh_dashboard_configuration_path}
	echo -e "opensearch.requestHeadersAllowlist: [\"securitytenant\",\"Authorization\"]" >> ${wazuh_dashboard_configuration_path}
	echo -e "opensearch_security.multitenancy.enabled: false" >> ${wazuh_dashboard_configuration_path}
	echo -e "opensearch_security.readonly_mode.roles: [\"kibana_read_only\"]" >> ${wazuh_dashboard_configuration_path}
	echo -e "server.ssl.enabled: true" >> ${wazuh_dashboard_configuration_path}
	echo -e "server.ssl.key: \"/etc/wazuh-dashboard/certs/dashboard-key.pem\"" >> ${wazuh_dashboard_configuration_path}
	echo -e "server.ssl.certificate: \"/etc/wazuh-dashboard/certs/dashboard.pem\"" >> ${wazuh_dashboard_configuration_path}
	echo -e "opensearch.ssl.certificateAuthorities: [\"/etc/wazuh-dashboard/certs/root-ca.pem\"]" >> ${wazuh_dashboard_configuration_path}
	echo -e "uiSettings.overrides.defaultRoute: /app/wazuh" >> ${wazuh_dashboard_configuration_path}

	# Deploy certificates
	einfo "Deploying certificates"
	einfo

	read -p "Node name : " node_name

	if [[ -z "${node_name}" ]]; then
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
		error 1
	fi 

	export NODE_NAME="${node_name}"
	mkdir /etc/wazuh-dashboard/certs
	tar -xf "${certificates_path}" -C /etc/wazuh-dashboard/certs/ ./${NODE_NAME}.pem ./${NODE_NAME}-key.pem ./root-ca.pem
	mv -n /etc/wazuh-dashboard/certs/${NODE_NAME}.pem /etc/wazuh-dashboard/certs/dashboard.pem
	mv -n /etc/wazuh-dashboard/certs/${NODE_NAME}-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
	chmod 500 /etc/wazuh-dashboard/certs
	chmod 400 /etc/wazuh-dashboard/certs/*
	chown -R "${WD_USER}":"${WD_USER}" /etc/wazuh-dashboard/certs

	# Change owner of important directories to wazuh dashboard user
	einfo "Set the right owner to the wazuh dashboard home directory"
	chown -R "${WD_USER}":"${WD_USER}" /usr/share/wazuh-dashboard

	einfo "Set the right owner to the wazuh config directory"
	chown -R "${WD_USER}":"${WD_USER}" /etc/wazuh-dashboard

	# Start wazuh dashboard service
	einfo
	einfo "Start wazuh dashboard service"
	einfo
	/etc/init.d/wazuh-dashboard start

	read -p "Would you like to start Wazuh dashboard service at boot ? [y/n] " start_at_boot
	
	if [[ -z "${start_at_boot}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
    fi 

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add wazuh-dashboard
    fi



	#read -p "Which installation mode is used ? [standalone/distributed] " install_mode
#
	#if [[ -z "${install_mode}" ]]; then
    #    eerror "Empty value not allowed !"
    #    exit 1
	#fi	
}
