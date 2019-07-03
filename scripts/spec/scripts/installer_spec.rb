require 'spec_helper'

RSpec.describe 'install.sh' do
  include_context 'run script in tmp dir'
  include_context 'build subject'

  BRANCH='master'
  PLAYBOOK_PATH="centos_provision-#{BRANCH}/playbook.yml"

  let(:stored_values) { {} }
  let(:script_name) { 'install.sh' }

  let(:ssl) { 'no' }
  let(:ssl_domains) { nil }
  let(:skip_firewall) { 'yes' }
  let(:license_ip) { '8.8.8.8' }
  let(:license_key) { 'WWWW-XXXX-YYYY-ZZZZ' }
  let(:db_restore_path) { nil }
  let(:db_restore_salt) { nil }
  let(:default_command_stubs) do
      {
        'ansible-playbook': '/bin/true',
        ansible: '/bin/true',
        curl: '/bin/true',
        iptables: '/bin/true',
        tar: '/bin/true',
        yum: '/bin/true',
      }
  end

  let(:prompts) do
    {
      en: {
        skip_firewall: 'Do you want to skip installing firewall?',
        ssl: 'Do you want to install Free SSL certificates (you can do it later)?',
        ssl_domains: 'Please enter domains separated by comma without spaces',
        license_key: 'Please enter license key',
        db_restore_path: 'Please enter the path to the SQL dump file if you want to restore database',
        db_restore_salt: 'Please enter the value of the "salt" parameter from the old config (application/config/config.ini.php)',
      },
      ru: {
        ssl: 'Установить бесплатные SSL сертификаты (можно сделать это позже)?',
        license_key: 'Укажите лицензионный ключ',
        db_restore_path: 'Укажите путь к файлу c SQL дампом, если хотите восстановить базу данных из дампа'
      }
    }
  end

  let(:user_values) do
    {
      skip_firewall: skip_firewall,
      ssl: ssl,
      ssl_domains: ssl_domains,
      license_key: license_key,
      db_restore_path: db_restore_path,
      db_restore_salt: db_restore_salt,
    }
  end

  it_behaves_like 'should try to detect bash pipe mode'

  it_behaves_like 'should print usage when invoked with', args: '-s -x'

  it_behaves_like 'should detect language'

  it_behaves_like 'should support russian prompts'

  it_behaves_like 'should not run under non-root'

  shared_examples_for 'inventory contains value' do |field, value|
    it "inventory file contains field #{field.inspect} with value #{value.inspect}" do
      run_script(inventory_values: stored_values)
      expect(@inventory.values[field]).to match(value)
    end
  end

  shared_examples_for 'inventory does not contain field' do |field|
    it "inventory file does not contain field #{field.inspect}" do
      run_script(inventory_values: stored_values)
      expect(@inventory.values).not_to have_key(field)
    end
  end

  describe 'fields' do
    # `-s` option disables yum/ansible checks
    # `-p` option disables invoking install commands

    let(:options) { '-spl en' }

    shared_examples_for 'field without default' do |field, value: 'user-value'|
      context 'field not stored in inventory' do
        it_behaves_like 'should not show default value', field

        it_behaves_like 'should store user value', field, readed_inventory_value: value
      end

      it_behaves_like 'should take value from previously saved inventory', field, value: value
    end

    shared_examples_for 'field with default' do |field, default:, user_value: 'user-value'|
      context 'field not stored in inventory' do
        it_behaves_like 'should show default value', field, showed_value: default

        it_behaves_like 'should store default value', field, readed_inventory_value: default

        it_behaves_like 'should store user value', field, readed_inventory_value: user_value
      end

      it_behaves_like 'should take value from previously saved inventory', field
    end

    shared_examples_for 'password field' do |field|
      context 'field not stored in inventory' do
        it_behaves_like 'should show default value', field, showed_value: /\w{16}/

        it_behaves_like 'should store default value', field, readed_inventory_value: /\w+{16}/

        it_behaves_like 'should store user value', field, readed_inventory_value: 'user-value'
      end

      it_behaves_like 'should take value from previously saved inventory', field
    end

    shared_examples_for 'should take value from previously saved inventory' do |field, value: 'stored-value'|
      context 'field stored in inventory' do
        let(:stored_values) { {field => value} }

        it_behaves_like 'should show default value', field, showed_value: value, inventory_values: {field => value}

        it_behaves_like 'should store default value', field, readed_inventory_value: value

        it_behaves_like 'should store user value', field, readed_inventory_value: value
      end
    end

    shared_examples_for 'should store default value' do |field, readed_inventory_value:|
      let(:prompts_with_values) { make_prompts_with_values(:en).merge(prompts[:en][field] => nil) }

      it_behaves_like 'inventory contains value', field, readed_inventory_value
    end

    shared_examples_for 'should store user value' do |field, readed_inventory_value:|
      let(:prompts_with_values) { make_prompts_with_values(:en).merge(prompts[:en][field] => readed_inventory_value) }

      it_behaves_like 'inventory contains value', field, readed_inventory_value
    end

    context 'should detect ip' do
      let(:options) { '-p' }
      let(:docker_image) { 'centos' }
      let(:commands) { [
        'echo "echo 127.0.0.1; echo 1.1.1.1" > /bin/hostname',
        'chmod a+x /bin/hostname'
      ] }

      it_behaves_like 'should store default value', :license_ip, readed_inventory_value: '1.1.1.1'
    end

    it_behaves_like 'field without default', :license_key, value: 'AAAA-BBBB-CCCC-DDDD'

    it_behaves_like 'inventory contains value', :evaluated_by_installer, 'yes'

    describe 'correctly stores yes/no fields' do
      it_behaves_like 'should print to', :log, /Writing inventory file.*ssl=no/m
    end
  end

  describe 'inventory file' do
    describe 'kversion field' do
      context '-k option missed' do
        let(:options) { '-s -p' }
        before { run_script(inventory_values: stored_values) }
        it { expect(@inventory.values).not_to have_key(:kversion) }
      end

      context '-k specified' do
        let(:options) { '-s -p -k 9' }
        before { run_script(inventory_values: stored_values) }
        it { expect(@inventory.values[:kversion]).to eq('9') }
      end

      context 'specified -k with wrong value' do
        let(:options) { '-s -p -k 10' }
        it_behaves_like 'should exit with error', "Specified Keitaro release '10' is not supported"
      end
    end

    describe 'cpu_cores' do
    end
  end

  context 'without actual installing software' do
    let(:options) { '-p' }
    let(:docker_image) { 'centos' }

    before(:all) { `docker rm keitaro_installer_test &>/dev/null` }

    shared_examples_for 'should install keitaro' do
      it_behaves_like 'should print to', :stdout,
                      %r{curl -fsSL https://github.com/.*/#{BRANCH}.tar.gz | tar xz}

      it_behaves_like 'should print to', :stdout,
                      "ansible-playbook -vvv -i #{Inventory::INVENTORY_FILE} #{PLAYBOOK_PATH}"

      context '-t specified' do
        let(:options) { '-p -t tag1,tag2' }

        it_behaves_like 'should print to', :stdout,
                        "ansible-playbook -vvv -i #{Inventory::INVENTORY_FILE} #{PLAYBOOK_PATH} --tags tag1,tag2"
      end

      context '-i specified' do
        let(:options) { '-p -i tag1,tag2' }

        it_behaves_like 'should print to', :stdout,
                        "ansible-playbook -vvv -i #{Inventory::INVENTORY_FILE} #{PLAYBOOK_PATH} --skip-tags tag1,tag2"
      end
    end

    context 'yum presented' do
      describe 'should upgrade system' do
        let(:command_stubs) { default_command_stubs }

        it_behaves_like 'should print to', :stdout, 'yum update -y'
      end
    end

    context 'yum presented, ansible presented' do
      let(:command_stubs) { default_command_stubs }

      it_behaves_like 'should print to', :log, "Try to found yum\nFOUND"
      it_behaves_like 'should print to', :log, "Try to found ansible\nFOUND"
      it_behaves_like 'should not print to', :stdout, 'yum install -y ansible'

      it_behaves_like 'should install keitaro'
    end

    context 'yum presented, ansible not presented' do
      let(:command_stubs) { {yum: '/bin/true', curl: '/bin/false'} }

      it_behaves_like 'should print to', :log, "Try to found yum\nFOUND"
      it_behaves_like 'should print to', :log, "Try to found ansible\nNOT FOUND"
      it_behaves_like 'should print to', :stdout, 'yum install -y epel-release'
      it_behaves_like 'should print to', :stdout, 'yum install -y ansible'

      it_behaves_like 'should install keitaro'
    end

    context 'yum not presented' do
      let(:commands) { ['rm /usr/bin/yum'] }
      it_behaves_like 'should print to', :log, "Try to found yum\nNOT FOUND"
      it_behaves_like 'should exit with error', 'This installer works only on CentOS'
    end
  end

  describe 'installation result' do
    let(:commands) { [
      'echo "echo 127.0.0.1; echo 8.8.8.8" > /bin/hostname',
      'chmod a+x /bin/hostname'
    ] }

    let(:docker_image) { 'centos' }

    context 'successful installation' do
      let(:command_stubs) { default_command_stubs }

      it_behaves_like 'should print to', :stdout,
                      %r{Everything is done!\nhttp://8.8.8.8/admin\nlogin: admin\npassword: \w+}
    end

    context 'unsuccessful installation' do
      let(:command_stubs) { default_command_stubs.merge('ansible-playbook': '/bin/false') }

      it_behaves_like 'should exit with error', [
        %r{There was an error evaluating current command\n(.*\n){3}.* ansible-playbook},
        'Installation log saved to install.log',
        'Configuration settings saved to .keitaro/installer_config',
        'You can rerun `curl -fsSL https://keitaro.io/install.sh > run; bash run`'
      ]
    end
  end

  describe 'nat support checking' do

    let(:docker_image) { 'centos' }

    context 'nat is not supported' do
      let(:command_stubs) { default_command_stubs.merge(iptables: '/bin/false') }

      it_behaves_like 'should print to', :stdout,
                      'It looks that your system does not support firewall'

      it_behaves_like 'inventory contains value', :skip_firewall, 'yes'

      context 'user cancels installation' do
        let(:skip_firewall) { 'no' }

        it_behaves_like 'should exit with error', 'Please run this program in system with firewall support'
      end
    end

    context 'nat is supported' do
      let(:command_stubs) { default_command_stubs }

      it_behaves_like 'should not print to', :stdout,
                      'It looks that your system does not support firewall'

      it_behaves_like 'inventory contains value', :skip_firewall, 'no'
    end
  end

  describe 'dump checking' do
    let(:docker_image) { 'centos' }
    let(:command_stubs) { default_command_stubs }
    let(:commands) { [%Q{echo "echo #{mime_type}" > /bin/file}, 'chmod a+x /bin/file'] }

    let(:db_restore_salt) { 'some.salt' }

    context 'valid plain text dump' do
      let(:mime_type) { 'text/plain' }
      let(:copy_files) { ["#{ROOT_PATH}/spec/files/valid.sql"] }
      let(:db_restore_path) { 'valid.sql' }

      it_behaves_like 'should print to', :stderr, 'Checking SQL dump . OK'
      it_behaves_like 'should print to', :log,
                      /head -n \d+ 'valid.sql'/,
                      /tail -n \d+ 'valid.sql'/
      it_behaves_like 'should print to', :log,
                      "TABLES_PREFIX='keitaro_' ansible-playbook "
    end

    context 'valid gzipped dump' do
      let(:mime_type) { 'application/x-gzip' }
      let(:copy_files) { ["#{ROOT_PATH}/spec/files/valid.sql.gz"] }
      let(:db_restore_path) { 'valid.sql.gz' }

      it_behaves_like 'should print to', :stderr, 'Checking SQL dump . OK'
      it_behaves_like 'should print to', :log,
                      /zcat 'valid.sql.gz' | head -n \d+/,
                      /zcat 'valid.sql.gz' | tail -n \d+/
      it_behaves_like 'should print to', :log,
                      "TABLES_PREFIX='keitaro_' ansible-playbook "
    end

    context 'dump is invalid' do
      let(:mime_type) { 'text/plain' }
      let(:copy_files) { ["#{ROOT_PATH}/spec/files/invalid.sql"] }
      let(:db_restore_path) { ['invalid.sql', ''] }

      it_behaves_like 'should print to', :stderr, 'Checking SQL dump . NOK'
    end

    context 'dump is invalid' do
      let(:mime_type) { 'application/x-gzip' }
      let(:copy_files) { ["#{ROOT_PATH}/spec/files/invalid.sql.gz"] }
      let(:db_restore_path) { ['invalid.sql.gz', ''] }

      it_behaves_like 'should print to', :stderr, 'Checking SQL dump . NOK'
    end
  end

  describe 'fails if keitaro is already installed' do
    let(:docker_image) { 'centos' }
    let(:commands) { ['mkdir -p /var/www/keitaro/var', 'touch /var/www/keitaro/var/install.lock'] }

    it_behaves_like 'should exit with error', 'Keitaro is already installed'
  end

  describe 'ssl enabled' do
    let(:options) { '-spL en' }

    let(:ssl) { 'yes' }
    let(:ssl_domains) { 'd1.com,d2.com' }

    it_behaves_like 'should print to', :stdout, 'Enabling SSL . SKIPPED'
    it_behaves_like 'should print to', :log,
                    %r{curl -fsSL https://keitaro.io/enable-ssl.sh \| bash -s -- -L en -D d1.com,d2.com}
  end
end
