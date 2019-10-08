require 'pry'

path = File.join('data')

# find all files
# match /
mention_regex = /(\B@[a-zA-Z]*)/g
# add them to an array and dedup
# print them

all_matches = []
Dir.glob("data/**/*.txt") do |fn|
  text = File.read(fn)
  all_matches + text.scan(mention_regex)
end

binding.pry
