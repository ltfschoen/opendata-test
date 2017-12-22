module DSL
  module Constants
    module OpenDataAPI
      # Transport for NSW (TfNSW) Open Data API
      BASE_URL = 'https://api.transport.nsw.gov.au/v1'
      REQUEST_LIMIT = 3
      module TrafficVolumeCountsAPI
        # Traffic Volume Counts API
        API_ENDPOINT = '/roads/spatial'
        PARAM_FORMAT = 'geojson'
        API_KEY = ENV['OPENDATA_TRAFFIC_VOLUME_COUNTS_API_KEY']
        # Generate the Query String Parameters for API Request
        # Example: OpenDataAPI::TrafficVolumeCountsAPI.query_string_params('geojson', 'road_traffic_counts_station_reference', '50')
        def self.query_string_params(format, table, limit)
          "?format=#{format}&q=select%20*%20from%20#{table}%20limit%20#{limit}%20"
        end 
      end
    end
  end
end
