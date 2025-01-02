require "sinatra"
require "dotenv/load"

require "http"
require "logger"
require "rqrcode"

set :logging, true
set :dump_errors, true

logger = Logger.new($stdout)
logger.level = Logger::DEBUG

HTTP.default_options = HTTP::Options.new(
  features: {
    logging: {
      logger:
    }
  }
)

get "/" do
  code = get_code
  return "Error retriving login code" unless code

  qrcode = RQRCode::QRCode.new(code)
  return qrcode.as_svg
end

def get_code
  puts "Trying with current access token"
  puts "access_token: #{$access_token}"
  puts "refresh_token: #{$refresh_token}"
  puts "expires_at: #{$expires_at}"

  qr = if $access_token && $expires_at && Time.now < $expires_at
    get_qr
  end

  return qr if qr

  $access_token = nil # reset access token

  refresh_user_token if $refresh_token

  puts "Trying with refreshed access token"
  qr = get_qr
  return qr if qr

  puts "Trying with new access token"
  user_token
  get_qr
end

def user_token
  params = {
    access_token: app_token,
    appName: "vivagym",
    email: ENV["EMAIL"],
    password: ENV["PASSWORD"]
  }

  body = URI.encode_www_form(params)

  response = HTTP
    .headers("Content-Type" => "application/x-www-form-urlencoded")
    .post("#{ENV["BASE_URL"]}/api/v2.0/en/exerp/newAuth", body:)

  return unless response.status.success?

  $access_token = response.parse.dig("access_token")
  $refresh_token = response.parse.dig("refresh_token")
  $expires_at = Time.now + response.parse.dig("expires_in").to_i # seconds

  $access_token
end

def refresh_user_token
  return unless $refresh_token

  response = HTTP
    .get("#{ENV["BASE_URL"]}/api/email/refresh?refresh_token=#{$refresh_token}")

  return unless response.status.success?

  $access_token = response.parse.dig("access_token")
  $refresh_token = response.parse.dig("refresh_token")
  $expires_at = Time.now + response.parse.dig("expires_in").to_i # seconds

  $access_token
end

def get_qr
  return unless $access_token

  response = HTTP
    .headers("Authorization" => "Bearer #{$access_token}")
    .get("#{ENV["BASE_URL"]}/api/v2.0/exerp/qr")

  response.status.success? && response.parse
end

def app_token
  json = {
    client_secret: ENV["CLIENT_SECRET"],
    client_id: ENV["CLIENT_ID"],
    grant_type: "client_credentials"
  }

  response = HTTP.post("#{ENV["BASE_URL"]}/oauth/v2/token", json:)

  raise "Failed to get app token" unless response.status.success?

  response.parse.dig("access_token")
end
