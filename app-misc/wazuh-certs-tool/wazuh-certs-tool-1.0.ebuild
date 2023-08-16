# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Wazuh certs tool"
HOMEPAGE="https://wazuh.com"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

S="${WORKDIR}"

src_install(){
    certs_working_dir="/usr/share/wazuh-certificates"
    certs_config_file="${certs_working_dir}/config.yml"
    einfo "Creating working directoy for certificates generation : ${certs_working_dir}"
    mkdir -p "${certs_working_dir}"
    cd "${certs_working_dir}"

    einfo "Downloading Wazuh script"
    curl -sO https://packages.wazuh.com/4.4/wazuh-certs-tool.sh
}

pkg_postinst() {
	elog "To generate certificates, run the following command :"
    elog
	elog "\t# emerge --config \"=${CATEGORY}/${PF}\""
	elog
}

pkg_config() {
    einfo "Wazuh script will be use to generate certificates"

    certs_working_dir="/usr/share/wazuh-certificates"
    certs_config_file="${certs_working_dir}/config.yml"
    cd "${certs_working_dir}"

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

	if [[ ! -s "./wazuh-certificates.tar" ]]; then
	    eerror "Issue when creating certificates !"
	    exit 1
	fi 

    einfo "Wazuh certs are in ${certs_working_dir}/wazuh-certificiates.tar"
    einfo "Copy the wazuh-certificates.tar file to all nodes if you use distributed deployment"
    einfo "Use the same directory (${certs_working_dir}) and the tar file name in all nodes to deploy automatically certificates"
}
