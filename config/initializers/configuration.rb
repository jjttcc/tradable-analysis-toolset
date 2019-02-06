
Rails.configuration.mas_host = 'localhost'
if ENV['TATPORT']
  Rails.configuration.mas_port1 = ENV['TATPORT']
else
  Rails.configuration.mas_port1 = 5441
end
Rails.configuration.mas_ports = [Rails.configuration.mas_port1, 5442,
                                 5443, 5444]

Rails.configuration.earliest_year = 1950
Rails.configuration.latest_year = DateTime.now.year + 10

Rails.configuration.data_setup = lambda do
  class DataConfig
    def data_retriever
      TiingoDataRetriever.new(data_retrieval_token)
    end

    def data_storage_manager
      FileTradableStorage.new(mas_data_path, data_retriever)
    end

    EOD_ENV_VAR = 'TIINGO_TOKEN'
    DATA_PATH_ENV_VAR = 'MAS_RUNDIR'

    def data_retrieval_token
      result = ENV[EOD_ENV_VAR]
      if result.nil? || result.empty? then
        raise "EOD data token environment variable #{EOD_ENV_VAR} not set."
      end
      result
    end

    def mas_data_path
      result = ENV[DATA_PATH_ENV_VAR]
      if result.nil? || result.empty? then
        raise "data path environment variable #{DATA_PATH_ENV_VAR} not set."
      end
      result
    end

  end

  DataConfig.new
end
