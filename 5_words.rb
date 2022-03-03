words = File.read("tmp/word_list.txt").split("\n").map(&:downcase).select{|w| w.length == 5 && w.split("").uniq.length == 5}
terms = words.map{|w| w.split("").sort}.uniq

buckets = terms.inject(Hash[("a".."z").to_a.map{|c| [c,[]]}]){|h, term| term.each{|l| h[l] = h[l] << term };h}
  
def search(path, buckets)
  puts path.inspect if path.length > 3
  if buckets.length == 0
    [path]
  else
    possible_terms = buckets.min_by{|_, v| v.length}.last
    possible_terms.flat_map do |term|
      ruled_out = term.inject([]){|a, c| a + buckets[c]}.uniq
      remaining = buckets.transform_values {|v| v - ruled_out}.delete_if{|_,v| v.empty?}
      if remaining.length == buckets.length - 5
        search(path + [term], remaining)
      else
        []
      end
    end
  end
end
  
# ("a".."z").to_a.flat_map do |c|
#   puts "Removing #{c}"
#   search([], buckets.transform_values{|v| v - buckets[c]}.delete_if{|_,v| v.empty?})
# end

# Find words

distinct_sets = [
  [["a", "f", "q", "s", "w"], ["b", "e", "i", "m", "x"], ["d", "h", "o", "v", "z"], ["g", "p", "r", "t", "y"], ["c", "k", "l", "n", "u"]],
  [["a", "f", "q", "s", "w"], ["c", "e", "i", "m", "x"], ["d", "h", "o", "v", "z"], ["b", "k", "l", "n", "u"], ["g", "p", "r", "t", "y"]],
  [["a", "f", "q", "s", "w"], ["c", "i", "l", "x", "y"], ["d", "h", "o", "v", "z"], ["e", "k", "m", "p", "t"], ["b", "g", "n", "r", "u"]],
  [["d", "f", "j", "o", "r"], ["b", "e", "i", "v", "x"], ["a", "l", "t", "w", "z"], ["c", "g", "k", "s", "u"], ["h", "m", "n", "p", "y"]],
  [["d", "f", "j", "o", "r"], ["b", "e", "i", "v", "x"], ["a", "l", "t", "w", "z"], ["g", "m", "p", "s", "y"], ["c", "h", "k", "n", "u"]],
  [["a", "f", "q", "s", "w"], ["b", "j", "m", "u", "y"], ["d", "h", "o", "v", "z"], ["e", "g", "l", "n", "t"], ["c", "i", "k", "p", "r"]],
  [["a", "f", "q", "s", "w"], ["b", "j", "m", "u", "y"], ["d", "h", "o", "v", "z"], ["e", "g", "k", "n", "r"], ["c", "i", "l", "p", "t"]],
  [["a", "f", "q", "s", "w"], ["b", "j", "m", "u", "y"], ["d", "h", "o", "v", "z"], ["g", "i", "l", "n", "p"], ["c", "e", "k", "r", "t"]],
  [["a", "f", "q", "s", "w"], ["j", "m", "p", "u", "y"], ["d", "h", "o", "v", "z"], ["b", "g", "i", "l", "n"], ["c", "e", "k", "r", "t"]],
  [["a", "f", "q", "s", "w"], ["j", "m", "p", "u", "y"], ["d", "h", "o", "v", "z"], ["b", "c", "i", "k", "r"], ["e", "g", "l", "n", "t"]],
]

distinct_sets.each do |distinct_set|
  anagrams = distinct_set.map do |letters|
    words.select{|word| letters.all?{|l| word.include?(l) } }.join("|")
  end
  puts anagrams.sort.join(", ")
end
