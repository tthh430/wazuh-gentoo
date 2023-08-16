# Wazuh Gentoo Repository

Gento Wazuh ebuilds

Wazuh home : [https://wazuh.com](https://wazuh.com)

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

### 1. Install Wazuh Indexer

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
