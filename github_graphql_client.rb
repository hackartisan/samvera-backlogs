# Run it like $ GITHUB_TOKEN=my_token pry -r './github_graphql_client.rb'
# do something like this with it:
# > download_all
# or
# > downloader.download_prs

require "graphlient"
require "json"
require "date"

DATA_DIR = "data"
API_URL = "https://api.github.com/graphql"
TOKEN = ENV["GITHUB_TOKEN"] || "you_need_a_token"
puts TOKEN

class Downloader
  BATCH_SIZE = 100

  def initialize(client:, repository_url:, base_dir:)
    @client = client
    @organization, @repository = parse_repository_url(repository_url)
    @open_path = File.join(base_dir, "open_issues", "raw")
    @recent_path = File.join(base_dir, "recent_issues", "raw")
    @merged_path = File.join(base_dir, "merged_prs", "raw")
    [@open_path, @recent_path, @merged_path].each do |path|
      FileUtils.mkdir_p(path)
    end
  end

  def download_issues
    download_data(type: "issues") do |doc|
      save_issue(doc: doc, project: "#{@organization}_#{@repository}")
    end
  end

  def download_prs
    download_data(type: "pullRequests") do |doc|
      save_pr(doc: doc, project: "#{@organization}_#{@repository}")
    end
  end

  def download_data(type:)
    cursor = nil
    loop do
      response = download_batch(cursor: cursor, type: type)
      sc_type = type.gsub(/(?<!^)[A-Z]/) { "_#$&" }.downcase
      documents = response.data.organization.repository.send("#{sc_type}".to_sym).edges
      break if documents.count == 0
      puts "  Downloading #{sc_type} #{documents.first.node.number} through #{documents.last.node.number}"
      documents.each do |doc|
        yield(doc.node)
      end
      cursor = documents.last.cursor
    end
  end

  def comment_bodies(doc)
    doc.comments.nodes.map { |n| n.body.gsub("\n", " ") }
  end

  def body_text(doc)
    doc.body_text.gsub("\n", " ")
  end

  # base_dir/merged_prs/raw/pr_2
  def save_pr(doc:, project:)
    text = [doc.title, body_text(doc)].flatten

    if doc.merged
      path = File.join(@merged_path, "#{project}_pr_#{doc.number}.txt")
      File.open(path, "w") { |f| f.write(text.join("\n")) }
    end
  end

  def save_issue(doc:, project:)
    last_year = Date.today.prev_year
    created_date = Date.parse(doc.created_at)

    text = [doc.title, body_text(doc), comment_bodies(doc)].flatten

    # for open issues, title, description, and comments
    if !doc.closed
      path = File.join(@open_path, "#{project}_issue_#{doc.number}.txt")
      File.open(path, "w") { |f| f.write(text.join("\n")) }
    end

    # for recent issues, just title and description
    if created_date > last_year
      path = File.join(@recent_path, "#{project}_issue_#{doc.number}.txt")
      File.open(path, "w") { |f| f.write(text[0, 2].join("\n")) }
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

  # setting pagination on comments and labels to max allowed;
  # don't expect we'll ever see that many.
  def issues_fields
    <<-FIELDS
      title
      bodyText
      comments (first: 100) {
        nodes {
          body
        }
      }
      number
      closed
      createdAt
    FIELDS
  end

  def pullrequests_fields
    <<-FIELDS
      title
      bodyText
      number
      merged
    FIELDS
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
  downloader = Downloader.new(client: github, repository_url: repos.first[:url], base_dir: DATA_DIR)
end

def download_all
  github = GithubClient.new(token: TOKEN).client
  repos.each do |repo|
    puts repo[:url]
    d = Downloader.new(client: github, repository_url: repo[:url], base_dir: DATA_DIR)
    d.download_issues
    d.download_prs
  end
end
