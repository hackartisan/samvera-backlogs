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

def write_clean_document

  @open_path = File.join(base_dir, "open_issues", "raw")
  @recent_path = File.join(base_dir, "recent_issues", "raw")
  @merged_path = File.join(base_dir, "merged_prs", "raw")
  [@open_path, @recent_path, @merged_path].each do |path|
    FileUtils.mkdir_p('data/*/clean')
  end
  blacklist = CSV.parse(File.read('usernames.csv'))

  Dir.glob("data/**/*.txt") do |fn|
    text = File.read(fn)

    blacklist.each do |term|
      text.gsub(term, "")
    end

    new_fn = fn.gsub('raw', 'clean')
    File.open(new_fn, 'w') do |f|
      f.write text
    end
  end


end
