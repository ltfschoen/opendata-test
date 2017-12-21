# Dotenv - https://github.com/bkeepers/dotenv
require 'dotenv'
Dotenv.load

require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'openssl'

# Transport for NSW (TfNSW) Open Data API
BASE_URL = 'https://api.transport.nsw.gov.au/v1'
# Traffic Volume Counts API
API_ENDPOINT = '/roads/spatial'
PARAM_FORMAT = 'geojson'
PARAM_TABLE = 'road_traffic_counts_station_reference'
PARAM_LIMIT = '50'
QUERY_STRING_PARAMS = "?format=#{PARAM_FORMAT}&q=select%20*%20from%20#{PARAM_TABLE}%20limit%20#{PARAM_LIMIT}%20"

uri = URI.parse(BASE_URL + API_ENDPOINT + QUERY_STRING_PARAMS)
puts "URI: #{uri.to_s}"
puts uri.host
puts uri.port
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true if uri.scheme == 'https'
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
http.read_timeout = 500
request = Net::HTTP::Get.new(uri)

request.initialize_http_header({
  "Accept" => "application/json",
  "Content-Type" => "application/json",
  "Authorization" => "apikey #{ENV['OPENDATA_TRAFFIC_VOLUME_COUNTS_API_KEY']}",
  "User-Agent" => "ruby/net::http"
})

puts "Request Headers: #{request.to_hash.inspect}"
Net::HTTP.start(uri.hostname, uri.port,
  :use_ssl => uri.scheme == 'https') do |http|
  response = http.request(request) # Net::HTTPResponse object
  case response
  when Net::HTTPSuccess then
    puts """Response:\n\t
    Code: #{response.code}\n\t
    Message: #{response.message}\n\t
    Class: #{response.class.name}\n\t
    Headers: \n #{JSON.pretty_generate(response.to_hash)}
    Body: \n #{JSON.pretty_generate(JSON.parse(response.body))}
    """
  when Net::HTTPRedirection then
    puts Net::HTTP.get(URI.parse(response['location']))
  else
    puts response.inspect
  end
end
