require 'mechanize'
require 'logger'


def run
  agent = Mechanize.new
  agent.log = Logger.new "mech.log"
  agent.user_agent_alias = 'Mac Safari'

  search_term = ARGV.join(" ")
  search_results = agent.post "http://www.top40db.net/find/title.asp", "Match" => search_term
  puts "Search term: [#{search_term}]"
  # Ask use which link to follow
  selected_link = filter_by_song(search_results.links_with :href => /Song/)

  # Ask which artist to select
  search_results = selected_link.click
  selected_link = filter_by_artist(search_results.links_with :href => /(find|lyrics)/)

  results_page = selected_link.click
  lyrics_html = results_page.search "div#divTOP40DB_LYRICS"

  # Clean them up
  to_del = lyrics_html.children.to_a.select { |node| node.name == "p" }
  to_del.map { |e| e.remove }
  
  puts lyrics_html.children.map { |i| "#{i.text}\n" }
end

def filter_by_song(song_links)
  puts "Select a match:"
  song_links.each_with_index { |link, index| puts "#{index+1}. #{link.text}" }
  print "Select [1 to #{song_links.length}]:"
  STDOUT.flush
  
  selection = STDIN.gets.chomp.to_i - 1
  song_links[selection]
end

def filter_by_artist(song_artist_links)
  matches = song_artist_links.each_slice(2).to_a  # [song, artist]
  matches.each_with_index do |tuple, index|
    puts "#{index+1}. #{tuple[1].text} (\"#{tuple[0].text}\")"
  end
  STDOUT.flush
  print "Select [1 to #{matches.length}]:"

  # First element of tuple is a song link
  selection = STDIN.gets.chomp.to_i - 1
  matches[selection][0]
end

run()
