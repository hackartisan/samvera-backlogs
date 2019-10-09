require 'pry'
require 'csv'

def print_snail_terms
  mention_regex = /(\B@[a-zA-Z0-9]*)/
  all_matches = []

  Dir.glob("data/**/*.txt") do |fn|
    text = File.read(fn)
    all_matches << text.scan(mention_regex)
  end

  all_matches.flatten.group_by { |i| i }.map { |k,v| [k, v.count] }.to_h.sort_by { |k,v| v }.each do |mentions|
    puts(" #{mentions[1]}: #{mentions[0]}")
  end
end

def email_regex
  %r{(?:[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])}
end

def url_regex
  URI::regexp(%w(http https))
end

def write_clean_documents
  ["open_issues", "recent_issues", "merged_prs"].each do |path|
    FileUtils.mkdir_p("data/#{path}/clean")
  end

  blacklist = CSV.parse(File.read('usernames.csv'))

  Dir.glob("data/**/*.txt") do |fn|
    text = File.read(fn)

    blacklist.each do |term|
      text.gsub!(term[0], "")
      text.gsub!(email_regex, "")
      text.gsub!(url_regex, "")
    end

    new_fn = fn.gsub('raw', 'clean')
    File.open(new_fn, 'w') do |f|
      f.write text
    end
    puts new_fn
  end
end

write_clean_documents
