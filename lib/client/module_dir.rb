require 'fileutils'

module DTK::Network::Client
  # Operations for managing module folders
  class ModuleDir
    # def self.local_dir_exists?(type, name, opts = {})
    #   File.exists?("#{base_path(type)}/#{name}")
    # end

    # def self.ret_base_path(type, name)
    #   "#{base_path(type)}/#{name}"
    # end

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

    def self.create_tar_gz(gzip_name, target_dir, source_dir_or_file = '.')
      target = "#{target_dir}/#{gzip_name}.tar.gz"
      `tar -czf #{target} #{source_dir_or_file}`
      target
    end

  end
end

