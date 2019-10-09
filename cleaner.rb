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

# TODO: clean email addresses, urls?

def write_clean_documents
  ["open_issues", "recent_issues", "merged_prs"].each do |path|
    FileUtils.mkdir_p("data/#{path}/clean")
  end

  blacklist = CSV.parse(File.read('usernames.csv'))

  Dir.glob("data/**/*.txt") do |fn|
    text = File.read(fn)

    blacklist.each do |term|
      text = text.gsub(term[0], "")
    end

    new_fn = fn.gsub('raw', 'clean')
    File.open(new_fn, 'w') do |f|
      f.write text
    end
    puts new_fn
  end
end

write_clean_documents
