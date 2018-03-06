#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK::Network::Client::Util
  module OsUtil
    require 'readline'

    DTK_HOME_DIR = 'dtk'
    DTK_MODULES_DIR = 'modules'
    DTK_MODULES_GZIP_DIR = '.download_location'

    def home_dir
      is_windows? ? home_dir__windows : genv(:home)
    end

    def dtk_local_folder
      "#{home_dir}/#{DTK_HOME_DIR}"
    end

    def dtk_modules_location
      @download_location ||= DTK::Network::Client::Config.module_download_location || "#{dtk_local_folder}/#{DTK_MODULES_DIR}"
    end

    def dtk_modules_gzip_location
      "#{dtk_local_folder}/#{DTK_MODULES_DIR}/#{DTK_MODULES_GZIP_DIR}"
    end

    def temp_dir
      is_windows? ? genv(:temp) : '/tmp'
    end

    def current_dir
      Dir.getwd
    end

    def delim
      is_windows? ? '\\' : '/'
    end

    private

    def genv(name)
      ENV[name.to_s.upcase].gsub(/\\/,'/')
    end

    def is_mac?
      RUBY_PLATFORM.downcase.include?('darwin')
    end

    def is_windows?
      RUBY_PLATFORM =~ /mswin|mingw|cygwin/
    end

    def home_dir__windows
      "#{genv(:homedrive)}#{genv(:homepath)}"
    end

    def is_linux?
      RUBY_PLATFORM.downcase.include?('linux')
    end
  end
end

