# encoding: UTF-8

require_relative 'lib/batting_averages_ui'

class Display < Thor
  desc "Batting Averages CLI app", "display, filter teams batting averages from CSV data"
  def batting_averages_ranking
    repl = BattingAveragesUi.new
    repl.launch
  end
end