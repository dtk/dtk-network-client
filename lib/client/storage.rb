module DTK::Network::Client
  class Storage
    def initialize(adapter, data)
      adapter_clazz = adapter_class(adapter)
      @adapter = adapter_clazz.new(data)
    end

    def upload(data)
      @adapter.upload(data)
    end

    def download(data, opts = {})
      @adapter.download(data, opts)
    end

    private

    def adapter_class(adapter)
      require_relative "storage/adapters/#{adapter}"
      Storage::Adapter.const_get(adapter.to_s.capitalize)
    end
  end
end
