require "graphlient"
require "json"

DATA_DIR = "data"
API_URL = "https://api.github.com/graphql"
TOKEN = ENV["GITHUB_TOKEN"] || "you_need_a_token"
puts TOKEN

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
          issues(first:2) {
            nodes {
              comments
              labels
              number
              title
              bodyText
              closed
              milestone
              createdAt
            }
          }
        }
      }
    }
    GRAPHQL
    response
  end

  # parse out org and repo name
  # return an array of json text objects?
  def download_prs(repository_url:, dir:)
    response = client.query <<~GRAPHQL
    query {
      organization(login: "pulibrary") {
        repository(name: "figgy") {
          pullRequests(first:2) {
            nodes {
              comments
              labels
              number
              title
              bodyText
              merged
              milestone
              createdAt
            }
          }
        }
      }
    }
    GRAPHQL
    response
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

def run
  repos = RepositoryList.new(path: "repositories.json").parse
  puts repos.first
  github = GithubGraph.new(token: TOKEN)
  github.download_issues(repository_url: repos.first[:url], dir: DATA_DIR)
end
