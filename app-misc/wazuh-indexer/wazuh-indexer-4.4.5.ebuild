# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Wazuh Indexer"
HOMEPAGE="https://wazuh.com"
SRC_URI="https://packages.wazuh.com/4.x/yum/${P}-1.x86_64.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="sys-apps/coreutils
app-arch/rpm2targz"
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

pkg_config() {

    # Create wazuh-indexer user
    wazuh_indexer_user="wazuh-indexer"
    if [[ $(getent passwd "${wazuh_indexer_user}" | grep -c "${wazuh_indexer_user}") -eq 0 ]]; then
        einfo "${wazuh_indexer_user} user does not exist"
        einfo "Creating ${wazuh_indexer_user} user"
        useradd -d /dev/null -c "Wazuh Indexer user" -M -r -U -s /sbin/nologin "${wazuh_indexer_user}" > /dev/null
   
        if  [[ $(getent passwd "${wazuh_indexer_user}" | grep -c "${wazuh_indexer_user}") -eq 1 ]]; then
            einfo "${wazuh_indexer_user} user created"
        else
            eerror "Error during ${wazuh_indexer_user} user creation"
            exit 1
        fi
    else
        einfo "${wazuh_indexer_user} user already exist. Skip!"
    fi
    einfo

    # Replace /usr/bin/bash by /bin/bash in all files in /usr/share/wazuh-indexer/bin
    einfo "Replace /usr/bin/bash by /bin/bash in all files in /usr/share/wazuh-indexer/bin"
    einfo
    cd /usr/share/wazuh-indexer/bin
    grep -ri "/usr/bin/bash" | cut -d":" -f1  | while read -r line; do
        sed -i 's%/usr/bin/bash%/bin/bash%g' "${line}"
    done

    # Certifcates
    read -p "Would you like to use your own PKI or use the wazuh tools to create certificates ? [pki/wazuh] " certificate

    if [[ -n "${certificate}" ]]; then
        case "${certificate}" in 
            "pki")
                einfo "Please refer to the documentation to know where install your certificates"
                einfo
                ;;
            
            "wazuh")
                einfo "Wazuh script will be use to generate certificates"

                certs_working_dir="/usr/share/wazuh-certificates"
                certs_config_file="${certs_working_dir}/config.yml"
                einfo "Creating working directoy for certificates generation : ${certs_working_dir}"
                mkdir -p "${certs_working_dir}"
                cd "${certs_working_dir}"

                einfo "Downloading Wazuh script"
                curl -sO https://packages.wazuh.com/4.4/wazuh-certs-tool.sh

                einfo "Script does not support clustering (multi nodes of each component) deployment"
                einfo "Only standalone (all on the the same server) and distributed (one node of each component) deployment"
                read -p "Which kind of deployment will you use ? [standalone/distributed] " deployment_method

                if [[ -n "${deployment_method}" ]]; then
                    case "${deployment_method}" in
                        "standalone")
                            read -p "Node name : " node_name
                            read -p "Node IP : " node_ip

                            if [[ -z "${node_name}" || -z "${node_ip}" ]]; then
                                eerror "Please feel node name and node ip"
                                exit 1
                            fi

                            indexer_name=${node_name}
                            indexer_ip=${node_ip}
                            server_name=${node_name}
                            server_ip=${node_ip}
                            dashboard_name=${node_name}
                            dashboard_ip=${node_ip}
                            ;;

                        "distributed")
                            read -p "Indexer name : " indexer_name
                            read -p "Indexer IP : " indexer_ip
                            read -p "Server name : " server_name
                            read -p "Server IP : " server_ip
                            read -p "Dashboard name : " dashboard_name
                            read -p "Dashboard IP : " dashboard_ip

                            if [[ -z "${indexer_name}" || -z "${indexer_ip}" || -z "${server_name}" || -z "${server_ip}" || -z "${dashboard_name}" || -z "${dashboard_ip}" ]]; then
                                eerror "Please feel indexer, server, dashboard nodes information (name and ip)"
                                exit 1
                            fi
                            ;;

                        *)
                            eerror "Unknown option !"
                            eerror "Authorize values : 'standalone' or 'distributed'"
                            exit 1 

                            ;;
                    esac
                else
                    eerror "Empty value not allowed !"
                    eerror "Authorize values : 'standalone' or 'distributed'"
                    exit 1
                fi

                # Write config file
                # Indexer nodes part
                echo -e "nodes:" > ${certs_config_file}
                echo -e "  indexer:" >> ${certs_config_file}
                echo -e "    - name: ${indexer_name}" >> ${certs_config_file}
                echo -e "      ip: ${indexer_ip}" >> ${certs_config_file}
                echo >> ${certs_config_file}
                echo -e "  server:" >> ${certs_config_file}
                echo -e "    - name: ${server_name}" >> ${certs_config_file}
                echo -e "      ip: ${server_ip}" >> ${certs_config_file}
                echo -e "  dashboard:" >> ${certs_config_file}
                echo -e "    - name: ${dashboard_name}" >> ${certs_config_file}
                echo -e "      ip: ${dashboard_ip}" >> ${certs_config_file}
                
                # Generate certificates
                bash ./wazuh-certs-tool.sh -A

                # Compress all the necessary files
                tar -cvf ./wazuh-certificates.tar -C ./wazuh-certificates/ .

                # Remove certs creation dir
                rm -rf ./wazuh-certificates

                einfo "Wazuh certs are in ${certs_working_dir}/wazuh-certificiates.tar"
                einfo "Copy the wazuh-certificates.tar file to all nodes if you use distributed deployment"
                einfo "Use the same directory (${certs_working_dir}) and the tar file name in all nodes to deploy automatically certificates"
                ;;
            *)
                eerror "Unknown option !"
                eerror "Authorize values : 'pki' or 'wazuh'"
                exit 1
                ;;
        esac
    else
        eerror "Empty value not allowed !"
        eerror "Authorize values : 'pki' or 'wazuh'"
        exit 1
    fi
    einfo

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

    if [[ -z "${network_host}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
    fi 

    read -p "Cluster name : " cluster_name

     if [[ -z "${cluster_name}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
    fi 

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

    # Deploy certificates
    einfo "Deploying certificates"
    einfo

    export NODE_NAME="${indexer_name}"
    mkdir -p /etc/wazuh-indexer/certs
    cd ${certs_working_dir}
    tar -xf ./wazuh-certificates.tar -C /etc/wazuh-indexer/certs/ ./${NODE_NAME}.pem ./${NODE_NAME}-key.pem ./admin.pem ./admin-key.pem ./root-ca.pem
    mv -n /etc/wazuh-indexer/certs/${NODE_NAME}.pem /etc/wazuh-indexer/certs/indexer.pem
    mv -n /etc/wazuh-indexer/certs/${NODE_NAME}-key.pem /etc/wazuh-indexer/certs/indexer-key.pem
    chmod 500 /etc/wazuh-indexer/certs
    chmod 400 /etc/wazuh-indexer/certs/*

    # Change owner of important directories to wazuh-indexer user
    einfo "Change owner of /usr/share/wazuh-indexer to ${wazuh_indexer_user}"
    chown -R "${wazuh_indexer_user}":"${wazuh_indexer_user}" /usr/share/wazuh-indexer

    einfo "Change owner of /etc/wazuh-indexer to ${wazuh_indexer_user}"
    chown -R "${wazuh_indexer_user}":"${wazuh_indexer_user}" /etc/wazuh-indexer

    einfo "Change owner of /var/log/wazuh-indexer to ${wazuh_indexer_user}"
    chown -R "${wazuh_indexer_user}":"${wazuh_indexer_user}" /var/log/wazuh-indexer

    # Start wazuh-indexer service
    einfo
    einfo "Start wazuh-indexer service"
    einfo 
    /etc/init.d/wazuh-indexer start

    read -p "Would you like to start wazuh-indexer service at boot ? [y/n] " start_at_boot

    if [[ -z "${start_at_boot}" ]]; then
        eerror "Empty value not allowed !"
        exit 1
    fi 

    if [[ "${start_at_boot}" == "y" ]]; then
        rc-update add wazuh-indexer
    fi

    # Cluster initializaton
    einfo "Wazuh Indexer initialization"
    einfo
    /usr/share/wazuh-indexer/bin/indexer-security-init.sh

    # Test installation
    einfo "To test the installation ru nthe following command :"
    einfo "curl -k -u admin:admin https://<wazuh-indexer-ip>:9200"
    einfo "PLease replace 'wazuh-indexer-ip' with your wazuh indexer ip"
    einfo

    einfo "To check if the single node is working correctly, please the following command :"
    einfo "curl -k -u admin:admin https://<wazuh-indexer-ip>:9200/_cat/nodes?v"
    einfo "PLease replace 'wazuh-indexer-ip' with your wazuh indexer ip"
}
