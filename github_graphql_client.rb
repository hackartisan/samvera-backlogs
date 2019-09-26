require "graphlient"
require "json"

DATA_DIR = "data"
API_URL = "https://api.github.com/graphql"
TOKEN = ENV["GITHUB_TOKEN"] || "you_need_a_token"
puts TOKEN

class Downloader
  BATCH_SIZE = 100

  def initialize(client:, repository_url:, base_dir:)
    @client = client
    @organization, @repository = parse_repository_url(repository_url)
    @base_dir = base_dir
  end

  def download_issues
    download_data(type: "issues")
  end

  def download_prs
    download_data(type: "pullRequests")
  end

  def download_data(type:)
    cursor = nil
    loop do
      response = download_batch(cursor: cursor, type: type)
      sc_type = type.gsub(/(?<!^)[A-Z]/) { "_#$&" }.downcase
      documents = response.data.organization.repository.send("#{sc_type}".to_sym).edges
      puts "Number of documents #{documents.count}"
      documents.each do |doc|
        puts "  #{doc.cursor}"
        puts "  #{doc.node.number}"
      end
      break if documents.count == 0
      cursor = documents.last.cursor
    end
  end

  # return a tuple of organization and repository
  def parse_repository_url(url)
    url.split("/")[-2, 2]
  end

  def download_batch(cursor:, type:)
    response = @client.query <<~GRAPHQL
    query {
      organization(login: #{@organization}) {
        repository(name: #{@repository}) {
          #{type}(#{pagination_parameters(cursor: cursor)}) {
            edges {
              cursor
              node {
                #{send("#{type}_fields".downcase.to_sym)}
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

  def pullrequests_fields
    <<-FIELDS
      number
    FIELDS
    #comments
    #labels
    #title
    #bodyText
    #merged
    #milestone
    #createdAt
  end

  def issues_fields
    <<-FIELDS
      number
    FIELDS
      #comments
      #labels
      #title
      #bodyText
      #closed
      #milestone
      #createdAt
  end

  def pagination_parameters(cursor:)
    base = "first: 100"
    if cursor
      "#{base} after: \"#{cursor}\""
    else
      base
    end
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
  Downloader.new(client: github, repository_url: repos.first[:url], base_dir: DATA_DIR)
end

# do something like this with it:
#downloader.download_issues
