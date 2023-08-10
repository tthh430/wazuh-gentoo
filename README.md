# Wazuh Gentoo Repository

Gento Wazuh ebuilds

Wazuh home : [https://wazuh.com](https://wazuh.com)

## Add the repository

## Install Wazuh

### 1. Install Wazuh Indexer

Please check [wazuh indexer install page](https://documentation.wazuh.com/current/installation-guide/wazuh-indexer/index.html) for requirements.

```bash
# To install wazuh indexer
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

```bash 
# To install wazuh server
emerge -v app-misc/wazuh-server
# It will install wazuh manager and filebeat
```

After emerging wazuh-manager and filebeat packages, you need to complete the following steps :
- Configure Wazuh manager
- Configure Filebeat
- Test installation

#### 2.1 Configure Wazuh manager

```bash
# Initialize the environment
emerge --config "=app-misc/wazuh-manager-<version>"
# Replace <version> with the wazuh manager version
```

#### 2.2 Configure Filebeat

```bash
# Initialize the environment
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
emerge -v www-apps/wazuh-dashboard
```

After emerging wazuh-manager and filebeat packages, you need to complete the following steps :
- Configure Wazuh Dashboard

#### 3.1 Configure Wazuh Dashboard

```bash
# Initialize the environment
emerge --config "=app-misc/wazuh-dashboard-<version>"
# Replace <version> with the wazuh dashboard version
```

### 4. Securing your Wazuh installation

To securize the installation, please refer to [Wazuh documentation](https://documentation.wazuh.com/current/installation-guide/wazuh-dashboard/step-by-step.html#securing-your-wazuh-installation).

### 5. Install Wazuh Agent

Please check [wazuh agent install page](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/index.html) to see different awy to install it.

```bash 
# To install wazuh agent
WAZUH_MANAGER="<wazuh-manager-ip>" emerge -v app-misc/wazuh-agent
# Replace wazuh-manager-ip with your wazuh manager IP

# To start the service
rc-service start wazuh-agent

# To start the service at boot
rc-update add wazuh-agent
```
