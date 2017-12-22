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

def generate_request_for_api(http, uri, api_key)
  puts "Generating Request for URI: #{uri.to_s}\nURI Host/Port: #{uri.host}, #{uri.port}"

  http.use_ssl = true if uri.scheme == 'https'
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.read_timeout = OpenDataAPI::READ_TIMEOUT
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

uri = URI.parse(OpenDataAPI::BASE_URL)
http = Net::HTTP.new(uri.host, uri.port)

# Request for Traffic Volume Counts API
uri_traffic_volume_counts_api = URI.parse(
  OpenDataAPI::TrafficVolumeCountsAPI::BASE_URL + 
  OpenDataAPI::TrafficVolumeCountsAPI::API_ENDPOINT + 
  OpenDataAPI::TrafficVolumeCountsAPI.query_string_params('geojson', 'road_traffic_counts_station_reference', '50')
)
request_for_traffic_volume_counts_api = generate_request_for_api(http, uri_traffic_volume_counts_api, OpenDataAPI::API_KEY)

# Request for Trip Planner API
uri_trip_planner_api = URI.parse(
  OpenDataAPI::TripPlannerAPI::BASE_URL + 
  OpenDataAPI::TripPlannerAPI::API_ENDPOINT + 
  OpenDataAPI::TripPlannerAPI.query_string_params('rapidJSON', '151.2093', '-33.8688', '100')
)
request_for_trip_planner_api = generate_request_for_api(http, uri_trip_planner_api, OpenDataAPI::API_KEY)

# Fetch specific request
def fetch(http, request, limit = 10)
  raise "Too many HTTP redirects" if limit == 0
  response = http.request(request) # Net::HTTPResponse object
  
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
    fetch(http, request, limit - 1)
  else
    raise Exception.new("Unsupported HTTP Response #{response.inspect}")
  end
end

begin
  # Start HTTP(S) Session to re-use across multiple requests
  Net::HTTP.start(uri.hostname, uri.port,
    :use_ssl => uri.scheme == 'https') do |http|
    puts http.use_ssl? ? "HTTPS Session" : "HTTP Session"

    # Request #1 to Traffic Volume Counts API
    response1 = fetch(http, request_for_traffic_volume_counts_api, OpenDataAPI::REQUEST_LIMIT)

    # Request #2 to Trip Planner API
    response2 = fetch(http, request_for_trip_planner_api, OpenDataAPI::REQUEST_LIMIT)
  end
rescue Exception => e
  raise "Exception opening TCP connection: #{e}"
ensure
  http.finish if http.started?
end
