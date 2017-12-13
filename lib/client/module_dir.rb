require 'fileutils'

module DTK::Network::Client
  # Operations for managing module folders
  class ModuleDir
    extend DTK::Network::Client::Util::Tar

    def self.ret_path_with_current_dir(name)
      "#{Dir.getwd}/#{name.gsub(':','/')}"
    end

    def self.rm_f(path)
      FileUtils.rm_rf(path)
    end

    def self.delete_directory_content(path)
      FileUtils.rm_rf(Dir.glob("#{path}/*"))
    end

    def self.create_file_with_content(file_path, content)
      FileUtils.mkdir_p(File.dirname(file_path))
      File.open(file_path, 'w') { |f| f << content }
    end

    def self.create_and_ret_tar_gz(source_dir, opts = {})
      raise Error.new("Directory '#{source_dir}' does not exist!") unless Dir.exist?(source_dir)
      gzip(tar(source_dir, opts))
    end

    def self.ungzip_and_untar(file, target_dir)
      raise Error.new("File '#{file}' does not exist!") unless File.exist?(file)
      FileUtils.mkdir_p(target_dir)
      untar(ungzip(File.open(file, "rb")), target_dir)
    end

  end
end

