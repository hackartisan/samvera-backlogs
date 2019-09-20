require "graphlient"
require "json"

DATA_DIR = "data"
API_URL = "https://api.github.com/graphql"

token = ENV["GITHUB_TOKEN"] || "you_need_a_token"
puts token

class GithubGraph
  def initialize(token:)
    @token = token
  end

  # parse out org and repo name
  # return an array of json text objects?
  def download_issues(repository_url:, dir:)
    response = client.query <<~GRAPHQL
    query {
      organization(login: "pulibrary") {
        repository(name: "figgy") {
          issues(first:1) {
            nodes {
              createdAt
              bodyText
              title
              closed
            }
          }
        }
      }
    }
    GRAPHQL
    puts response.data.issues
  end

  private

    def client
      @client ||= Graphlient::Client.new(
        API_URL,
        headers: {
          "Authorization" => "bearer #{@token}",
          "Accept" => "application/vnd.github.hawkgirl-preview+json"
        }
      )
    end
end

class RepositoryList
  def initialize(path:)
    @path = path
  end

  # return an array of hashes
  # with symbols as keys, dangit
  def parse
    JSON.parse(File.read(@path)).map do |h|
      h.map do |k, v|
        [k.to_sym, v]
      end.to_h
    end
  end
end

repos = RepositoryList.new(path: "repositories.json").parse
puts repos.first
github = GithubGraph.new(token: token)
github.download_issues(repository_url: repos.first[:url], dir: DATA_DIR)
