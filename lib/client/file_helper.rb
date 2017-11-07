module DTK::Network::Client
  class FileHelper
    def self.get_content?(file_path)
      File.open(file_path).read if file_path && File.exists?(file_path)
    end
  end
end

