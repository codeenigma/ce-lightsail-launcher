#!/bin/bash

# Prepare the server
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

# Initial checkout of ce-provision
su - ce-dev -c "git clone --branch 1.x https://github.com/codeenigma/ce-provision.git /home/ce-dev/ce-provision"

ANSIBLE_DEFAULT_EXTRA_VARS="{_ce_provision_base_dir: $OWN_DIR, _ce_provision_build_dir: $BUILD_WORKSPACE, _ce_provision_build_tmp_dir: $BUILD_TMP_DIR, _ce_provision_data_dir: $ANSIBLE_DATA_DIR, _ce_provision_build_id: $BUILD_ID, _ce_provision_force_play: $FORCE_PLAY, target_branch: $TARGET_PROVISION_BRANCH}"

# Seed provision.yml
DOMAIN_NAME="www.example.com"
cat << END > /home/ce-dev/ce-provision/provision.yml
---
- hosts: localhost
  become: true
  vars:
    - _domain_name: $DOMAIN_NAME
    - _ce_provision_build_tmp_dir: /tmp
    - _ce_provision_data_dir: /tmp
    - is_local: true
    - _env_type: utility
    - ce_deploy:
        new_user: true
        key_name: id_rsa.pub
        own_repository: https://github.com/codeenigma/ce-deploy.git
        config_repository: https://github.com/codeenigma/ce-dev-ce-deploy-config.git
        own_repository_branch: 1.x
        config_repository_branch: 1.x
        username: ce-dev
        local_dir: /home/ce-dev/ce-deploy
        groups: []
    - ce_provision:
        new_user: true
        key_name: id_rsa.pub
        extra_repository: ""
        own_repository: https://github.com/codeenigma/ce-provision.git
        own_repository_branch: 1.x
        own_repository_skip_checkout: false
        config_repository: https://github.com/codeenigma/ce-dev-ce-provision-config.git
        config_repository_branch: 1.x
        config_repository_skip_checkout: false
        username: ce-dev
        local_dir: /home/ce-dev/ce-provision
        groups: []
        galaxy_custom_requirements_file: ""
  roles:
    - ce_provision
    - ce_deploy
END

# Install controller packages
set -x && \
cd /home/ce-dev/ce-provision && \
su - ce-dev -c "/usr/local/bin/ansible-playbook --extra-vars=\"{ansible_common_remote_group: ce-dev}\" /home/ce-dev/ce-provision/provision.yml"

# Seed provision.yml
cat << END > /home/ce-dev/ce-provision/provision.yml
---
- hosts: localhost
  become: true
  vars:
    - _domain_name: $DOMAIN_NAME
    - _env_type: dev
    - db_root_pass: ce-dev
    - project_name: lgd
    - user_root:
        authorized_keys: []
        delete_admin: false
    - mysql_client:
        host: localhost
        user: root
        password: ce-dev
        creds_file_dest: /home/ce-dev/.mysql.creds
        creds_file_owner: ce-dev
        creds_file_group: ce-dev
    - nginx:
        user: www-data
        worker_processes: auto
        events:
          worker_connections: 768
        http:
          server_names_hash_bucket_size: 256
          access_log: /var/log/nginx-access.log
          error_log: /var/log/nginx-error.log
          ssl_protocols: "TLSv1 TLSv1.1 TLSv1.2"
        log_group_prefix: ""
        php_fastcgi_backend: "127.0.0.1:90{{ php.version[-1] | replace('.','') }}"
        ratelimitingcrawlers: false
        client_max_body_size: "700M"
        fastcgi_read_timeout: 60
        overrides: []
        domains:
          - server_name: "_"
            access_log:  "/var/log/nginx-access.log"
            error_log:  "/var/log/nginx-error.log"
            error_log_level:  "notice"
            webroot:  "/home/ce-dev/deploy/live.local/web"
            project_type:  "drupal8"
            ratelimitingcrawlers: false
            is_default: true
            ssl: # @see the 'ssl' role.
              domains:
                - "{{ _domain_name }}"
              handling: selfsigned
            servers:
              - port: 80
                ssl: false
                https_redirect: false
              - port: 443
                ssl: true
                https_redirect: false
            upstreams: []
    - php:
        version:
          - 8.0
        cli:
          expose_php: "On"
          error_reporting: "E_ALL"
          display_errors: "On"
          display_startup_errors: "On"
          html_errors: "On"
          engine: "On"
          short_open_tag: "Off"
          max_execution_time: 120
          max_input_time: 60
          max_input_nesting_level: 64
          max_input_vars: 1000
          memory_limit: -1
          log_errors_max_len: 1024
          ignore_repeated_errors: "Off"
          ignore_repeated_source: "Off"
          post_max_size: 200M
          upload_max_filesize: 200M
          max_file_uploads: 20
          date_timezone: "Europe/London"
          overrides: {}
          opcache:
            enable: 1
            enable_cli: 0
            memory_consumption: 128
            max_accelerated_files: 2000
            validate_timestamps: 1
        fpm:
          expose_php: "On"
          error_reporting: "E_ALL"
          display_errors: "On"
          display_startup_errors: "On"
          html_errors: "On"
          engine: "On"
          short_open_tag: "Off"
          max_execution_time: 120
          max_input_time: 60
          max_input_nesting_level: 64
          max_input_vars: 1000
          memory_limit: 256M
          log_errors_max_len: 1024
          ignore_repeated_errors: "Off"
          ignore_repeated_source: "Off"
          post_max_size: 200M
          upload_max_filesize: 200M
          max_file_uploads: 20
          date_timezone: "Europe/London"
          pool_user: ce-dev
          pool_group: ce-dev
          default_socket_timeout: 60
          max_children: 5
          start_servers: 2
          min_spare_servers: 1
          max_spare_servers: 3
          process_idle_timeout: 10s
          max_requests: 500
          opcache:
            enable: 1
            enable_cli: 0
            memory_consumption: 128
            max_accelerated_files: 2000
            validate_timestamps: 1
    - php_composer:
        version: ''
        version_branch: '--2'
        keep_updated: true
        github_oauth_token: ''
  tasks:
    - name: Update the apt cache.
      ansible.builtin.apt:
        update_cache: true
    - name: Install common packages.
      ansible.builtin.import_role:
        name: _meta/common_base
    - name: Configure MariaDB installation script.
      ansible.builtin.debconf:
        name: mariadb-server
        question: "{{ item }}"
        vtype: password
        value: "{{ db_root_pass }}"
      with_items:
        - mysql-server/root_password
        - mysql-server/root_password_again
    - name: Install MariaDB with custom configuration.
      ansible.builtin.apt:
        name: mariadb-server
        state: latest
        update_cache: true
      register: install_mariadb
    - name: Install the MySQL client.
      ansible.builtin.import_role:
        name: mysql_client
    - name: Set up the PHP CLI.
      ansible.builtin.import_role:
        name: php-cli
    - name: Set up PHP-FPM.
      ansible.builtin.import_role:
        name: php-fpm
    - name: Set up Nginx web server.
      ansible.builtin.import_role:
        name: nginx
END

# Install web server packages
set -x && \
cd /home/ce-dev/ce-provision && \
su - ce-dev -c "/usr/local/bin/ansible-playbook --extra-vars=\"{ansible_common_remote_group: ce-dev}\" /home/ce-dev/ce-provision/provision.yml"

# Configure MariaDB
set -x && \
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password; ALTER USER 'root'@'localhost' IDENTIFIED BY 'ce-dev'; FLUSH PRIVILEGES;"

# Seed deploy.yml
su - ce-dev -c "mkdir -p /home/ce-dev/deploy/live.local"
cat << END > /home/ce-dev/deploy/live.local/deploy.yml
---
- hosts: localhost
  vars:
    - project_name: localgovdrupal
    - project_type: drupal8
    - webroot: web
    - build_type: local
    - _env_type: dev
    - _domain_name: $DOMAIN_NAME
    # Path to your project root.
    - deploy_path: /home/ce-dev/deploy/live.local
    # This actually does not take any backup, but is needed to populate settings.php.
    - mysql_backup:
        handling: none
        credentials_handling: static
    # A list of Drupal sites (for multisites).
    - drupal:
        sites:
          - folder: "default"
            public_files: "sites/default/files"
            install_command: "-y si localgov"
            # Toggle config import on/off. Disabled for initial passes.
            config_import_command: ""
            # config_import_command: "cim"
            config_sync_directory: "config/sync"
            sanitize_command: "sql-sanitize"
            # Remove after initial pass, to avoid reinstalling Drupal.
            force_install: true
            base_url: "https://{{ _domain_name }}"
    # Composer command to run.
    - composer:
        command: install
        no_dev: false
        working_dir: "{{ deploy_path }}"
        apcu_autoloader: false
    - drush:
        use_vendor: true
    - drush_bin: ../../../vendor/drush/drush/drush
    - lgd_modules:
        - localgov_alert_banner
        - localgov_directories
        - localgov_directories_db
        - localgov_directories_location
        - localgov_geo_address
        - localgov_geo
        - localgov_directories_page
        - localgov_directories_venue
        - localgov_events
        - localgov_geo_area
        - localgov_guides
        - localgov_news
        - localgov_search
        - localgov_search_db
        - localgov_services_status
        - localgov_step_by_step
        - localgov_subsites
        - localgov_subsites_paragraphs
        - localgov_homepage_paragraphs
        - localgov_workflows
        - localgov_review_date
  pre_tasks:
    - name: Download composer file.
      ansible.builtin.get_url:
        url: https://raw.githubusercontent.com/drupal/recommended-project/9.3.x/composer.json
        dest: "{{ deploy_path }}/composer.json"
        force: false
    - name: Enable composer-patches plugin.
      ansible.builtin.command:
        cmd: composer config --no-plugins allow-plugins.cweagans/composer-patches true
        chdir: "{{ deploy_path }}"
    - name: Install drush.
      ansible.builtin.command:
        cmd: composer require drush/drush:11.*
        chdir: "{{ deploy_path }}"
    - name: Install LocalGov Drupal.
      ansible.builtin.command:
        cmd: composer require localgovdrupal/localgov
        chdir: "{{ deploy_path }}"
    - name: Add the CE repository.
      ansible.builtin.command:
        cmd: composer config repositories.codeenigma vcs https://github.com/codeenigma/ce_localgovdrupal_config
        chdir: "{{ deploy_path }}"
    - name: Install CE LocalGov Drupal Config.
      ansible.builtin.command:
        cmd: composer require codeenigma/ce_localgovdrupal_config
        chdir: "{{ deploy_path }}"
  roles:
    - _init # Sets some variables the deploy scripts rely on.
    - composer # Composer install step.
    - database_backup # This is still needed to generate credentials.
    - config_generate # Generates settings.php
    - database_apply # Run drush updb and config import.
    - _exit # Some common housekeeping.
  post_tasks:
    - name: Install Localgov Drupal demo content field dependencies.
      ansible.builtin.command:
        cmd: "{{ drush_bin }} -y en default_content condition_field tablefield geofield_map geocoder_field field_formatter_class dynamic_entity_reference datetime_range date_recur_modular
search_api_db search_api_autocomplete entity_reference_facet_link"
        chdir: "{{ deploy_path }}/{{ webroot }}/sites/{{ drupal.sites[0].folder }}"
      ignore_errors: true
    - name: Install Localgov Drupal demo content other dependencies.
      ansible.builtin.command:
        cmd: "{{ drush_bin }} -y en leaflet_views entity_hierarchy fontawesome dbal diff preview_link responsive_preview schema_metatag schema_article entity_hierarchy_breadcrumb layout_paragraphs layout_discovery viewsreference scheduled_transitions"
        chdir: "{{ deploy_path }}/{{ webroot }}/sites/{{ drupal.sites[0].folder }}"
      ignore_errors: true
    - name: Install Localgov Drupal modules.
      ansible.builtin.command:
        cmd: "{{ drush_bin }} -y en {{ item }}"
        chdir: "{{ deploy_path }}/{{ webroot }}/sites/{{ drupal.sites[0].folder }}"
      with_items: "{{ lgd_modules }}"
      ignore_errors: true
    - name: Install Workflows module for LocalGov Drupal.
      ansible.builtin.command:
        cmd: "{{ drush_bin }} -y en localgov_workflows"
        chdir: "{{ deploy_path }}/{{ webroot }}/sites/{{ drupal.sites[0].folder }}"
      ignore_errors: true
    - name: Install Review Date and Directories modules for LocalGov Drupal.
      ansible.builtin.command:
        cmd: "{{ drush_bin }} -y en localgov_directories_org localgov_review_date"
        chdir: "{{ deploy_path }}/{{ webroot }}/sites/{{ drupal.sites[0].folder }}"
      ignore_errors: true
    - name: Install Code Enigma tweaks to LocalGov Drupal.
      ansible.builtin.command:
        cmd: "{{ drush_bin }} -y en ce_localgovdrupal_config"
        chdir: "{{ deploy_path }}/{{ webroot }}/sites/{{ drupal.sites[0].folder }}"
      ignore_errors: true
    - name: Install Localgov Drupal demo content.
      ansible.builtin.command:
        cmd: "{{ drush_bin }} -y en localgov_demo"
        chdir: "{{ deploy_path }}/{{ webroot }}/sites/{{ drupal.sites[0].folder }}"
      ignore_errors: true
END

# Deploy Drupal
set -x && \
cd /home/ce-dev/deploy/live.local && \
su - ce-dev -c "/bin/sh /home/ce-dev/ce-deploy/scripts/build.sh --workspace /home/ce-dev/deploy/live.local --playbook deploy.yml --build-number 0 --build-id celocalgovtemplate-dev"
