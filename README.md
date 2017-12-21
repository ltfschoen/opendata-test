# OpenData API

* About:
  * Ruby application to experiment with the [Transport for NSW Open Data API](https://opendata.transport.nsw.gov.au).

* Quick Start
  * Install dependencies
    ```
    bundle install
    ```
  * Run
    ```
    bundle exec ruby main.rb
    ```

* Setup Log
  * User Guide for OpenData API - https://opendata.transport.nsw.gov.au/user-guide
    * Register - https://opendata.transport.nsw.gov.au/user/register
    * Verify Password
    * Login

    * Create App
      * https://opendata.transport.nsw.gov.au/user/6773
      * Go to My Account > Applications
      * Click "Add Application"
        * Application Name - "congestion"
        * Link - https://opendata.transport.nsw.gov.au/application/congestion
      * Select API - "Traffic Volume Counts API", "Trip Planner API"
      * API Key - Add to .env file

    * Use API
      * Browse Data
        * Select an API
        * Choose how to use API
          * Click either "Explore API" (opens API Explorer), then set Authentication type as "API Key", then click "Expand Operations" to see resource details, method, parameters, and response messages for a query
          * Click "Download" (static datasets)
      * Developers > API Exporer - https://opendata.transport.nsw.gov.au/node/2171/exploreapi#!/default/get_spatial
      * Click the button "Try it out!"

  * Create Application
    * Create Ruby file main.rb
    * Create .env file
    * Setup Gemfile 
      * Go to http://bundler.io/
      * Run `gem install bundler`
      * Add demo contents to Gemfile
    * Add DotEnv Gem - https://github.com/bkeepers/dotenv
    * Use Net HTTP to create request to OpenData API to replicate the following cURL request
      ```
      curl -X GET --header 'Accept: application/json' --header 'Authorization: apikey <INSERT_API_KEY>' 'https://api.transport.nsw.gov.au/v1/roads/spatial?format=geojson&q=select%20*%20from%20road_traffic_counts_station_reference%20limit%2050%20'
      ```
    * Run with `bundle exec ruby main.rb`
