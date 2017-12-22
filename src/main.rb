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

# Traffic Volume Counts API
uri = URI.parse(
  OpenDataAPI::BASE_URL + OpenDataAPI::TrafficVolumeCountsAPI::API_ENDPOINT + 
  OpenDataAPI::TrafficVolumeCountsAPI.query_string_params('geojson', 'road_traffic_counts_station_reference', '50')
)

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
  "Authorization" => "apikey #{OpenDataAPI::TrafficVolumeCountsAPI::API_KEY}",
  "User-Agent" => "ruby/net::http"
})

puts "Request Headers: #{request.to_hash.inspect}"

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
    else
      http.finish
      raise Exception.new("Only JSON response supported")
    end
  when Net::HTTPRedirection then
    location = response['location']
    puts Net::HTTP.get(URI.parse(location))
    warn "Redirected to #{location}"
    request = Net::HTTP::Get.new(location)
    fetch(http, request, limit - 1)
  else
    puts response.inspect
  end
end

begin
  # Start HTTP Session
  Net::HTTP.start(uri.hostname, uri.port,
    :use_ssl => uri.scheme == 'https') do |http|
    puts http.use_ssl? ? "HTTPS Session" : "HTTP Session"
    fetch(http, request, OpenDataAPI::REQUEST_LIMIT)
  end
rescue Exception => e
  raise "Exception opening TCP connection: #{e}"
end
