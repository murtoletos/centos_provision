require 'shell'

RSpec.shared_context 'run script in tmp dir', run_script_in_tmp_dir: :yes do
  before do
    if ENV['HOME_DIR']
      @tmp_dir = Dir.mktmpdir('', "tmp")
      @copy_dir = Dir.pwd + '/' + @tmp_dir
      dir = ENV['HOME_DIR']
      @current_dir = "#{dir}/#{@tmp_dir}"
    else
      @current_dir = @tmp_dir = @copy_dir = Dir.mktmpdir('', '/tmp')
    end
  end
  before { @old_current_dir = Dir.pwd; Dir.chdir(@copy_dir) }
  before do
    FileUtils.copy("#{ROOT_PATH}/#{subject.script_command}", @copy_dir)
  end

  after { Dir.chdir(@old_current_dir) }
  after { FileUtils.rm_rf(@current_dir) }

  def run_script(inventory_values: {installer_version: Script::INSTALLER_RELEASE_VERSION})
    if defined?(copy_files)
      copy_files.each do |path_to_file|
        FileUtils.copy(path_to_file, @copy_dir)
      end
    end
    Inventory.write(inventory_values)
    subject.call(current_dir: "#{@current_dir}")
    @inventory = Inventory.read_from_log(subject.log)
  end
end
