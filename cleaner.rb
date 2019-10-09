require 'pry'

path = File.join('data')
mention_regex = /(\B@[a-zA-Z0-9]*)/
all_matches = []

Dir.glob("data/**/*.txt") do |fn|
  text = File.read(fn)
  all_matches << text.scan(mention_regex)
end

all_matches.flatten.group_by { |i| i }.map { |k,v| [k, v.count] }.to_h.sort_by { |k,v| v }.each do |mentions|
  puts(" #{mentions[1]}: #{mentions[0]}")
end

# TODO: clean email addresses, urls?
