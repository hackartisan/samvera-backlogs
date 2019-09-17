require "graphlient"

token = ENV["GITHUB_TOKEN"] || "you_need_a_token"
puts token
api_url = "https://api.github.com/graphql"

client = Graphlient::Client.new(api_url,
  headers: {
    "Authorization" => "bearer #{token}",
    "Accept" => "application/vnd.github.hawkgirl-preview+json"
  }
)

puts client.schema
