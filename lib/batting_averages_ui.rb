# encoding: UTF-8

require 'tty-spinner'
require 'tty-table'
require 'paint'

require_relative 'batting_averages_engine'

class BattingAveragesUi
  def initialize
    @last_command = ''
    @processor = BattingAveragesEngine.new
  end

  def launch
    spinner = TTY::Spinner.new("[:spinner] Loading CSV data", clear: false)
    spinner.run do |spinner|
      @processor.fetch_data!
      spinner.success('(loaded)')
    end

    spinner = TTY::Spinner.new("[:spinner] Building indexes", clear: false)
    spinner.run do |spinner|
      @processor.build_indexes!
      spinner.success('(done)')
    end

    answer_to('all')

    loop do
      puts "\nPress ENTER to reload the ranking, or type a specific command (type h|H|help|HELP to see available commands)"
      print Paint['|> ', :blue, :bright]

      user_command = STDIN.gets&.chomp
      
      if user_command.nil? || user_command =~ /^q$/i# Ctrl+D
        puts "Exiting, bye"
        break
      end
      
      answer_to(user_command)
    end
  end

private

  def answer_to(user_command)
    if user_changed_command?(user_command: user_command)
      @processor.reset_pagination!
      @last_command = user_command
    end

    case user_command.strip
    when /^h|help$/i
      puts "1. `all` or ENTER -> displays global ranking\n2. `in {4_digits_year}` -> displays ranking for this year\n3. `of {team_name}` -> displays ranking within this team from its inception\n4. `of {team_name} in {4_digits_year}` -> combination of 2 and 3\n5. `list years`\n6. `list teams`\n7. `n` or `next` -> go to next page\n8. `p` or `previous` -> back to previous page\n9. `q` or Ctrl+D -> exit"
    when /^list years$/i
      puts @processor.all_years.join(', ')
    when /^list teams$/i
      puts @processor.all_team_names.join(', ')
    when '', /^all$/i
      render_table(@processor.get_all)
    when /^of (.+) in (\d+)$/i
      if (has_team=@processor.has_team?($1)) && (has_year=@processor.has_year?($2))
        render_table(@processor.by(team: $1, year: $2))
      else
        puts "No data for #{$1}" unless has_year
        puts "Unknown team #{$1}" unless has_team
      end
    when /^in (\d{4})$/i
      if @processor.has_year?($1)
        render_table(@processor.by(year: $1))
      else
        puts "No data for #{$1}"
      end
    when /^of (.+)$/i
      if @processor.has_team?($1)
        render_table(@processor.by(team: $1))
      else
        puts "Unknown team #{$1}"
      end
    when /^n|next$/i
      @processor.next_page!
      answer_to(@last_command)
    when /^p|previous$/i
      @processor.previous_page!
      answer_to(@last_command)
    else
      puts "unknown command"
    end
  end

  def render_table(ranking_data=[])
    if ranking_data.empty?
      puts "No data to display"
      return
    end

    puts TTY::Table.new(['playerID', 'yearID', 'Team name(s)', 'Batting Average'], ranking_data).render(:ascii, alignments: [:left, :center, :left, :center], padding: [0,2])
  end

  def user_changed_command?(user_command: 'all')
    (user_command == '' || user_command =~ /^all|in\s+\d{4}|of\s+.+$/i) && user_command != @last_command
  end
end