module DSL
  module Constants
    module OpenDataAPI
      # Transport for NSW (TfNSW) Open Data API
      BASE_URL = 'https://api.transport.nsw.gov.au'
      API_KEY = ENV['OPENDATA_API_KEY']
      READ_TIMEOUT = 500
      REQUEST_LIMIT = 3

      module TrafficVolumeCountsAPI
        # Traffic Volume Counts API
        BASE_URL = 'https://api.transport.nsw.gov.au/v1'
        API_ENDPOINT = '/roads/spatial'
        PARAM_FORMAT = 'geojson'
        # Generate the Query String Parameters for API Request
        # Example: OpenDataAPI::TrafficVolumeCountsAPI.query_string_params('geojson', 'road_traffic_counts_station_reference', '50')
        def self.query_string_params(format, table, limit)
          "?format=#{format}&q=select%20*%20from%20#{table}%20limit%20#{limit}%20"
        end
      end

      # Reference: https://opendata.transport.nsw.gov.au/node/601/exploreapi#!/default/tfnsw_addinfo_request
      # Example Request: 'https://api.np.transport.nsw.gov.au/v1/tp/coord?outputFormat=rapidJSON&
      #   coord=151.206290%3A-33.884080%3AEPSG%3A4326&coordOutputFormat=EPSG%3A4326&inclFilter=1&
      #   type_1=GIS_POINT&radius_1=1000&PoisOnMapMacro=true&version=10.2.1.42'
      module TripPlannerAPI
        # Trip Planner API
        BASE_URL = 'https://api.np.transport.nsw.gov.au/v1'
        API_ENDPOINT = '/tp/coord'
        PARAM_FORMAT = 'rapidJSON'
        # Generate the Query String Parameters for API Request
        # Example: OpenDataAPI::TripPlannerAPI.query_string_params('rapidJSON', '151.2093', '-33.8688', '1000')
        def self.query_string_params(format, coord_long = '151.2093', coord_lat = '-33.8688', coord_radius = '1000')
          "?outputFormat=#{format}&coord=#{coord_long}%3A#{coord_lat}%3AEPSG%3A4326&inclFilter=1&" +
          "type_1=GIS_POINT&radius_1=#{coord_radius}&PoisOnMapMacro=true&version=10.2.1.42"
        end  
      end
    end
  end
end
