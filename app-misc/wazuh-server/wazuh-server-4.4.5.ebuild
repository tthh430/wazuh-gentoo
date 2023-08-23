# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Wazuh server is composed of Wazuh Manager and Filebeat-OSS"
HOMEPAGE="https://wazuh.com"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="amd64"

DEPEND="=app-misc/wazuh-manager-${PV}
=app-misc/filebeat-oss-7.10.2"

RDEPEND="${DEPEND}"
BDEPEND=""
