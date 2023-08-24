# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Wazuh Indexer"
HOMEPAGE="https://wazuh.com"
SRC_URI="https://packages.wazuh.com/4.x/yum/${P}-1.x86_64.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

DEPEND="acct-user/wazuh-indexer
acct-group/wazuh-indexer
sys-apps/coreutils
app-arch/rpm2targz
app-admin/sudo"
RDEPEND="${DEPEND}"
BDEPEND=""

QA_PREBUILT="usr/share/wazuh-indexer/*
usr/lib/*
etc/wazuh-indexer/*
etc/sysconfig/wazuh-indexer
etc/init.d/wazuh-indexer"

S="${WORKDIR}"

src_install(){
    cp -pPR "${S}"/usr "${D}"/ || die "Failed to copy files"
    cp -pPR "${S}"/etc "${D}"/ || die "Failed to copy files"
    cp -pPR "${S}"/var "${D}"/ || die "Failed to copy files"

    keepdir /var/log/wazuh-indexer
    keepdir /var/lib/wazuh-indexer

    newinitd "${FILESDIR}"/wazuh-indexer-initd wazuh-indexer
    newconfd "${FILESDIR}"/wazuh-indexer-confd wazuh-indexer
}

pkg_postinst() {
	elog "To finish the Wazuh Indexer install, you need to follow the following step :"
	elog
	elog "\t- Configure Wazuh indexer"
	elog

	elog "Execute the following command to configure Wazuh indexer"
	elog
	elog "\t# emerge --config \"=${CATEGORY}/${PF}\""
	elog
}

pkg_config() {

    # wazuh-indexer user
    WI_USER="wazuh-indexer"
    
    # Replace /usr/bin/bash by /bin/bash in all files in /usr/share/wazuh-indexer/bin
    einfo "Replace /usr/bin/bash by /bin/bash in all files in /usr/share/wazuh-indexer/bin"
    einfo
    cd /usr/share/wazuh-indexer/bin
    grep -ri "/usr/bin/bash" | cut -d":" -f1  | while read -r line; do
        sed -i 's%/usr/bin/bash%/bin/bash%g' "${line}"
    done

    # Configuring the wazuh indexer
    wazuh_indexer_config_file="/etc/wazuh-indexer/opensearch.yml"
    einfo "Configuring Wazuh indexer"
    einfo

    einfo "Address of this node for both HTTP and transport traffic."
    einfo "The node will bind to this address and use it as its publish address."
    einfo "Accepts an IP address or a hostname"
    einfo "Must bind name in certificate"
    read -p "Publish address : " network_host
    einfo

    [[ ! -z "${network_host}" ]] || die "Empty value not allowed !"

    read -p "Indexer name (must bind name in certs) : " indexer_name

    [[ ! -z "${indexer_name}" ]] || die "Empty value not allowed !"

    read -p "Cluster name : " cluster_name

    [[ ! -z "${cluster_name}" ]] || die "Empty value not allowed !"

    # Write indexer configuration
    echo -e "network.host: \"${network_host}\"" > ${wazuh_indexer_config_file}
    echo -e "node.name: \"${indexer_name}\"" >> ${wazuh_indexer_config_file}
    echo -e "cluster.initial_master_nodes:" >> ${wazuh_indexer_config_file}
    echo -e "- \"${indexer_name}\"" >> ${wazuh_indexer_config_file}
    echo -e "cluster.name: \"${cluster_name}\"" >> ${wazuh_indexer_config_file}
    echo -e "node.max_local_storage_nodes: \"3\"" >> ${wazuh_indexer_config_file}
    echo -e "path.data: /var/lib/wazuh-indexer" >> ${wazuh_indexer_config_file}
    echo -e "path.logs: /var/log/wazuh-indexer" >> ${wazuh_indexer_config_file}
    echo >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.http.pemcert_filepath: /etc/wazuh-indexer/certs/indexer.pem" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.http.pemkey_filepath: /etc/wazuh-indexer/certs/indexer-key.pem" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.http.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.transport.pemcert_filepath: /etc/wazuh-indexer/certs/indexer.pem" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.transport.pemkey_filepath: /etc/wazuh-indexer/certs/indexer-key.pem" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.http.enabled: true" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.transport.enforce_hostname_verification: false" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.ssl.transport.resolve_hostname: false" >> ${wazuh_indexer_config_file}
    echo >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.authcz.admin_dn:" >> ${wazuh_indexer_config_file}
    echo -e "- \"CN=admin,OU=Wazuh,O=Wazuh,L=California,C=US\"" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.check_snapshot_restore_write_privileges: true" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.enable_snapshot_restore_privilege: true" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.nodes_dn:" >> ${wazuh_indexer_config_file}
    echo -e "- \"CN=${indexer_name},OU=Wazuh,O=Wazuh,L=California,C=US\"" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.restapi.roles_enabled:" >> ${wazuh_indexer_config_file}
    echo -e "- \"all_access\"" >> ${wazuh_indexer_config_file}
    echo -e "- \"security_rest_api_access\"" >> ${wazuh_indexer_config_file}
    echo -e "plugins.security.system_indices.enabled: true" >> ${wazuh_indexer_config_file}
    echo -e 'plugins.security.system_indices.indices: [".plugins-ml-model", ".plugins-ml-task", ".opendistro-alerting-config", ".opendistro-alerting-alert*", ".opendistro-anomaly-results*", ".opendistro-anomaly-detector*", ".opendistro-anomaly-checkpoints", ".opendistro-anomaly-detection-state", ".opendistro-reports-*", ".opensearch-notifications-*", ".opensearch-notebooks", ".opensearch-observability", ".opendistro-asynchronous-search-response*", ".replication-metadata-store"]' >> ${wazuh_indexer_config_file}
    echo -e '### Option to allow Filebeat-oss 7.10.2 to work ###' >> ${wazuh_indexer_config_file}
    echo -e "compatibility.override_main_response_version: true" >> ${wazuh_indexer_config_file}

    # Deploy certificates

    read -p "Certificates tar file path on node : " certificates_path

	[[ ! -z ${certificates_path} ]] || die "Empty value not allowed !"

	[[ -s "${certificates_path}" ]] || die "${certificates_path} does not exist or is empty"

    einfo "Deploying certificates"
    einfo

    export NODE_NAME="${indexer_name}"
    mkdir -p /etc/wazuh-indexer/certs
    tar -xf "${certificates_path}" -C /etc/wazuh-indexer/certs/ ./${NODE_NAME}.pem ./${NODE_NAME}-key.pem ./admin.pem ./admin-key.pem ./root-ca.pem
    mv -n /etc/wazuh-indexer/certs/${NODE_NAME}.pem /etc/wazuh-indexer/certs/indexer.pem
    mv -n /etc/wazuh-indexer/certs/${NODE_NAME}-key.pem /etc/wazuh-indexer/certs/indexer-key.pem
    chmod 500 /etc/wazuh-indexer/certs
    chmod 400 /etc/wazuh-indexer/certs/*

    # Change owner of important directories to wazuh-indexer user
    einfo "Change owner of /usr/share/wazuh-indexer to ${WI_USER}"
    chown -R ${WI_USER}:${WI_USER} /usr/share/wazuh-indexer

    einfo "Change owner of /etc/wazuh-indexer to ${WI_USER}"
    chown -R ${WI_USER}:${WI_USER} /etc/wazuh-indexer

    einfo "Change owner of /var/log/wazuh-indexer to ${WI_USER}"
    chown -R ${WI_USER}:${WI_USER} /var/log/wazuh-indexer

    # Start wazuh-indexer service
    einfo
    einfo "Start wazuh-indexer service"
    einfo 
    /etc/init.d/wazuh-indexer start

    read -p "Would you like to start wazuh-indexer service at boot ? [y/n] " start_at_boot

    [[ ! -z "${start_at_boot}" ]] || die "Empty value not allowed !"

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add wazuh-indexer
    fi

    # Cluster initializaton
    einfo "Wazuh Indexer initialization"
    einfo
    /usr/share/wazuh-indexer/bin/indexer-security-init.sh

    # Test installation
    einfo "To test the installation run the following command :"
    einfo "# curl -k -u admin:admin https://<wazuh-indexer-ip>:9200"
    einfo "Replace 'wazuh-indexer-ip' with your wazuh indexer ip"
    einfo

    einfo "To check if the single node is working correctly, please the following command :"
    einfo "# curl -k -u admin:admin https://<wazuh-indexer-ip>:9200/_cat/nodes?v"
    einfo "Replace 'wazuh-indexer-ip' with your wazuh indexer ip"
}
