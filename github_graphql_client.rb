require "graphlient"
require "json"

DATA_DIR = "data"
API_URL = "https://api.github.com/graphql"
TOKEN = ENV["GITHUB_TOKEN"] || "you_need_a_token"
puts TOKEN

class Downloader
  def initialize(client:, repository_url:, dir:)
    @client = client
    @repository_url = repository_url
    @dir = dir
  end

  # parse out org and repo name
  # return an array of json text objects?
  def download_issues
    # the first time we won't have a cursor
    #cursor = nil
    #while cursor
    #  then run the thing
    #  cursor = response_is_empty? ? nil : last_items_cursor
    #end
    download_issue_batch
  end

    # from then on we will have a cursor, which we need to pull out of the
    #   response
    # at some point the cursor will be some terminal value? so test for that?
    # how do you know you're at the end?

  def download_issue_batch
    response = @client.query <<~GRAPHQL
    query {
      organization(login: "pulibrary") {
        repository(name: "figgy") {
          issues(first:2) {
            edges {
              cursor
              node {
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
            totalCount
          }
        }
      }
    }
    GRAPHQL
    response
  end

  # parse out org and repo name
  # return an array of json text objects?
  def download_prs
    response = @client.query <<~GRAPHQL
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

end

class GithubClient
  def initialize(token:)
    @token = token
  end

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

def repos
  RepositoryList.new(path: "repositories.json").parse
end

def downloader
  github = GithubClient.new(token: TOKEN).client
  Downloader.new(client: github, repository_url: repos.first[:url], dir: DATA_DIR)
end

# do something like this with it:
#downloader.download_issues
