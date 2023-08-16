# Wazuh Gentoo Repository

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/7c296f154be2472ab330739575e44b05)](https://app.codacy.com/gh/tthh430/wazuh-gentoo?utm_source=github.com&utm_medium=referral&utm_content=tthh430/wazuh-gentoo&utm_campaign=Badge_Grade)

Gento Wazuh ebuilds

Wazuh home : [https://wazuh.com](https://wazuh.com)

[Add the repository](#add-the-repository)\
[Install Wazuh](#install-wazuh)\
&nbsp;&nbsp;&nbsp;&nbsp;[Global information and requirements](#global-information-and-requitements)\
&nbsp;&nbsp;&nbsp;&nbsp;[1. Install Wazuh indexer](#1-install-wazuh-indexer)\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[1.1 Configure Wazuh indexer](#11-configure-wazuh-indexer)\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[1.2 Check the installation](#12-check-the-installation)\
&nbsp;&nbsp;&nbsp;&nbsp;[2.Install Wazuh server](#2-install-wazuh-server)\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[2.1 Configure Wazuh manager](#21-configure-wazuh-manager)\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[2.2 Configure Filebeat](#22-configure-filebeat)\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[2.3 Test Filebeat installation](#23-test-filebeat-installation)\
&nbsp;&nbsp;&nbsp;&nbsp;[3. Install Wazuh dashboard](#3-install-wazuh-dashboad)\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[3.1 Configure Wazuh dashboard](#31-configure-wazuh-dashboard)\
&nbsp;&nbsp;&nbsp;&nbsp;[4. Securing your Wazuh installation](#4-securing-your-wazuh-installation)\
&nbsp;&nbsp;&nbsp;&nbsp;[5. Install Wazuh agent](#5-install-wazuh-agent)\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[5.1 Configure Wazuh agent](#51-configure-wazuh-agent)

## Add the repository

```bash
# Add the following lines in a file names /etc/portage/repos.conf/wazuh-gentoo.conf
[wazuh-gentoo]
location = /var/db/repos/wazuh-gentoo
auto-sync = yes
sync-ury = https://github.com....
```

## Install Wazuh

### Global information and requitements

* PLease check Wazuh official documentation to be sure to have latest informations 
* You need root user privileges to install each component
* Please check the bug section to known known bugs and their workaround

### 1. Install Wazuh indexer

Please check [wazuh indexer install page](https://documentation.wazuh.com/current/installation-guide/wazuh-indexer/index.html) for requirements.

```bash
# To install wazuh indexer
echo "app-misc/wazuh-indexer ~amd64" >> /etc/portage/package.accept_keywords/wazuh-gentoo
emerge -v app-misc/wazuh-indexer
```

After emerging wazuh-indexer package, you need to complete the following steps :
- Configure Wazuh indexer
- Test the installation

#### 1.1 Configure Wazuh indexer

```bash
# Configure Wazuh indexer
emerge --config "=app-misc/wazuh-indexer-<version>"
# Replace <version> with the wazuh indexer version
```

#### 1.2 Check the installation

To test the cluster installation, please refer to the [Wazuh documentation](https://documentation.wazuh.com/current/installation-guide/wazuh-indexer/step-by-step.html#testing-the-cluster-installation).


### 2. Install Wazuh Server

Please check [wazuh server install page](https://documentation.wazuh.com/current/installation-guide/wazuh-server/index.html) for requirements.

The Wazuh server is composed of the Wazuh manager and Filebeat. 

**Do not install Wazuh Manager and Wazuh agent on the same host**

```bash 
# To install wazuh server
echo "app-misc/wazuh-server ~amd64" >> /etc/portage/package.accept_keywords/wazuh-gentoo
echo "app-misc/wazuh-manager ~amd64" >> /etc/portage/package.accept_keywords/wazuh-gentoo
echo "app-misc/filebeat-oss ~amd64" >> /etc/portage/package.accept_keywords/wazuh-gentoo
emerge -v app-misc/wazuh-server
# It will install wazuh manager and filebeat
```

After emerging wazuh-manager and filebeat packages, you need to complete the following steps :
- Configure Wazuh manager
- Configure Filebeat
- Test installation

#### 2.1 Configure Wazuh manager

```bash
# Configure Wazuh manager
emerge --config "=app-misc/wazuh-manager-<version>"
# Replace <version> with the wazuh manager version
```

#### 2.2 Configure Filebeat

```bash
# Configure Filebeat
emerge --config "=app-misc/filebeat-oss-<version>"
# Replace <version> with the filebeat version
```

#### 2.3 Test Filebeat installation

To test the installation, please refer to the [Wazuh documentation](https://documentation.wazuh.com/current/installation-guide/wazuh-server/step-by-step.html#starting-the-filebeat-service)

```bash
# To test the filebeat configuration
sudo -u filebeat-oss /usr/share/filebeat/bin/filebeat test config

# To test the filebeat output
sudo -u filebeat-oss /usr/share/filebeat/bin/filebeat test output
```

### 3. Install Wazuh Dashboad

Please check [wazuh dashboard install page](https://documentation.wazuh.com/current/installation-guide/wazuh-dashboard/index.html) for requirements.

```bash 
# To install wazuh dashboard
echo "www-apps/wazuh-dashboard ~amd64" >> /etc/portage/package.accept_keywords/wazuh-gentoo
emerge -v www-apps/wazuh-dashboard
```

After emerging wazuh-manager and filebeat packages, you need to complete the following steps :
- Configure Wazuh Dashboard

#### 3.1 Configure Wazuh Dashboard

```bash
# Configure Wazuh Dashboard
emerge --config "=app-misc/wazuh-dashboard-<version>"
# Replace <version> with the wazuh dashboard version
```

### 4. Securing your Wazuh installation

To securize the installation, please refer to [Wazuh documentation](https://documentation.wazuh.com/current/installation-guide/wazuh-dashboard/step-by-step.html#securing-your-wazuh-installation).

### 5. Install Wazuh Agent

**Do not install Wazuh Manager and Wazuh agent on the same host**

Please check [wazuh agent install page](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/index.html) to see different awy to install it.

```bash 
# To install wazuh agent
WAZUH_MANAGER="<wazuh-manager-ip>" emerge -v app-misc/wazuh-agent
# Replace wazuh-manager-ip with your wazuh manager IP
```

#### 5.1 Configure Wazuh Agent

```bash
# Configure Wazuh Agent
echo "app-misc/wazuh-agent ~amd64" >> /etc/portage/package.accept_keywords/wazuh-gentoo
emerge --config "=app-misc/wazuh-agent-<version>"
# Replace <version> with the wazuh agent version
```
