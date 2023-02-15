#!/bin/bash
set -x && \
export DEBIAN_FRONTEND=noninteractive && \
apt-get update && \
apt-get dist-upgrade -y -o Dpkg::Options::="--force-confnew" && \
apt-get install -y -o Dpkg::Options::="--force-confnew" \
  anacron \
  apt-transport-https \
  apt-utils \
  aptitude \
  bash \
  binutils \
  cron \
  curl \
  dirmngr \
  gnupg \
  rsync \
  openssh-server \
  postfix \
  procmail \
  python3-apt \
  python3-dev \
  python3-pycurl \
  python3-pip \
  rsyslog \
  sudo \
  systemd \
  systemd-sysv \
  unzip \
  vim \
  git \
  ca-certificates \
  git-lfs \
  openssh-client \
  nfs-common \
  stunnel4 \
  wget && \
apt-get clean  && \
update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \

# Set up ce-dev user
set -x && \
export DEBIAN_FRONTEND=noninteractive && \
useradd -s /bin/bash ce-dev && \
echo ce-dev:ce-dev | chpasswd -m && \
install -m 755 -o ce-dev -g ce-dev -d /home/ce-dev && \
install -m 700 -o ce-dev -g ce-dev -d /home/ce-dev/.ssh && \
echo root:ce-dev | chpasswd -m && \
echo 'ce-dev ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ce-dev && \
chmod 0440 /etc/sudoers.d/ce-dev && \

# Install Ansible
pip3 install ansible boto3 && \
git lfs install --skip-repo && \
update-alternatives --install /usr/bin/python python /usr/bin/python3 1

su - ce-dev -c "git clone --branch 1.x https://github.com/codeenigma/ce-provision.git /home/ce-dev/ce-provision"

ANSIBLE_DEFAULT_EXTRA_VARS="{_ce_provision_base_dir: $OWN_DIR, _ce_provision_build_dir: $BUILD_WORKSPACE, _ce_provision_build_tmp_dir: $BUILD_TMP_DIR, _ce_provision_data_dir: $ANSIBLE_DATA_DIR, _ce_provision_build_id: $BUILD_ID, _ce_provision_force_play: $FORCE_PLAY, target_branch: $TARGET_PROVISION_BRANCH}"
DOMAIN_NAME="www.example.com"

# Install controller packages
wget -O /home/ce-dev/ce-provision/setup.yml https://raw.githubusercontent.com/codeenigma/ce-lightsail-launcher/main/ansible/setup.yml
set -x && \
cd /home/ce-dev/ce-provision && \
su - ce-dev -c "/usr/local/bin/ansible-playbook --extra-vars=\"{ansible_common_remote_group: ce-dev, _domain_name: $DOMAIN_NAME}\" /home/ce-dev/ce-provision/setup.yml"

# Install web server packages
wget -O /home/ce-dev/ce-provision/provision.yml https://raw.githubusercontent.com/codeenigma/ce-lightsail-launcher/main/ansible/provision.yml
set -x && \
cd /home/ce-dev/ce-provision && \
su - ce-dev -c "/usr/local/bin/ansible-playbook --extra-vars=\"{ansible_common_remote_group: ce-dev, _domain_name: $DOMAIN_NAME}\" /home/ce-dev/ce-provision/provision.yml"

# Configure MariaDB
set -x && \
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password; ALTER USER 'root'@'localhost' IDENTIFIED BY 'ce-dev'; FLUSH PRIVILEGES;"

# Deploy Drupal
su - ce-dev -c "mkdir -p /home/ce-dev/deploy/live.local"
wget -O /home/ce-dev/ce-provision/deploy.yml https://raw.githubusercontent.com/codeenigma/ce-lightsail-launcher/main/ansible/deploy.yml
set -x && \
cd /home/ce-dev/deploy/live.local && \
su - ce-dev -c "/bin/sh /home/ce-dev/ce-deploy/scripts/build.sh --workspace /home/ce-dev/deploy/live.local --playbook deploy.yml --build-number 0 --build-id celocalgovtemplate-dev --ansible-extra-vars \"{_domain_name: $DOMAIN_NAME}\""
