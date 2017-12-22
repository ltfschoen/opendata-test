# Dotenv - https://github.com/bkeepers/dotenv
require 'dotenv'
Dotenv.load

require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'openssl'

require_relative '../config/config'
Object.instance_eval { 
  include DSL::Constants
}

class OpenDataAPIRequest
  attr_reader :request

  def initialize(http, uri, api_key)
    @http = http
    @uri = uri
    @api_key = api_key
    @request = self.generate_request_for_api(uri, api_key)
  end

  def generate_request_for_api(uri, api_key)
    puts "Generating Request for URI: #{uri.to_s}\nURI Host/Port: #{uri.host}, #{uri.port}"
  
    request = Net::HTTP::Get.new(uri)
    
    request.initialize_http_header({
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "Authorization" => "apikey #{api_key}",
      "User-Agent" => "ruby/net::http"
    })
    
    puts "Generated Request with Headers: #{request.to_hash.inspect}"
    request
  end

  # Fetch specific request
  def fetch(http_session, request, limit = 10)
    raise "Too many HTTP redirects" if limit == 0
    response = http_session.request(request) # Net::HTTPResponse object
    
    case response
    when Net::HTTPSuccess then
      if response['content-type'] =~ /json/i
        puts """Response:\n\t
        Code: #{response.code}\n\t
        Message: #{response.message}\n\t
        Class: #{response.class.name}\n\t
        Headers: \n #{JSON.pretty_generate(response.to_hash)}
        Body: \n #{JSON.pretty_generate(JSON.parse(response.body))}
        """ 
        puts "Response code #{response.code} for request to: #{request.uri}"
        response
      else
        raise Exception.new("Only JSON response supported")
      end
    when Net::HTTPRedirection then
      location = response['location']
      puts Net::HTTP.get(URI.parse(location))
      warn "Redirected to #{location}"
      request = Net::HTTP::Get.new(location)
      self.fetch(http_session, request, limit - 1)
    else
      raise Exception.new("Unsupported HTTP Response #{response.inspect}")
    end
  end
end

uri_base = URI.parse(OpenDataAPI::BASE_URL)
http_base = Net::HTTP.new(uri_base.host, uri_base.port)

# Request for Traffic Volume Counts API
uri_traffic_volume_counts_api = URI.parse(
  OpenDataAPI::TrafficVolumeCountsAPI::BASE_URL + 
  OpenDataAPI::TrafficVolumeCountsAPI::API_ENDPOINT + 
  OpenDataAPI::TrafficVolumeCountsAPI.query_string_params('geojson', 'road_traffic_counts_station_reference', '50')
)
request_for_traffic_volume_counts_api = OpenDataAPIRequest.new(http_base, uri_traffic_volume_counts_api, OpenDataAPI::API_KEY)

# Request for Trip Planner API
uri_trip_planner_api = URI.parse(
  OpenDataAPI::TripPlannerAPI::BASE_URL + 
  OpenDataAPI::TripPlannerAPI::API_ENDPOINT + 
  OpenDataAPI::TripPlannerAPI.query_string_params('rapidJSON', '151.2093', '-33.8688', '100')
)
request_for_trip_planner_api = OpenDataAPIRequest.new(http_base, uri_trip_planner_api, OpenDataAPI::API_KEY)

begin
  # Start HTTP(S) Session to re-use across multiple requests
  Net::HTTP.start(uri_base.hostname, uri_base.port,
    :use_ssl => uri_base.scheme == 'https') do |http_session|
    puts http_session.use_ssl? ? "HTTPS Session" : "HTTP Session"

    http_session.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http_session.read_timeout = OpenDataAPI::READ_TIMEOUT

    # Request #1 to Traffic Volume Counts API
    response1 = request_for_traffic_volume_counts_api.fetch(http_session, request_for_traffic_volume_counts_api.request, OpenDataAPI::REQUEST_LIMIT)

    # Request #2 to Trip Planner API
    response2 = request_for_trip_planner_api.fetch(http_session, request_for_trip_planner_api.request, OpenDataAPI::REQUEST_LIMIT)
  end
rescue Exception => e
  raise "Exception opening TCP connection: #{e}"
end
