# frozen_string_literal: true

require 'bundler'
Bundler.setup

require 'csv'
require 'ostruct'
require 'set'
require 'sorted_array_binary'

require_relative 'utils/paginator'

class BattingAveragesEngine
  include Utils::Paginator

  attr_accessor :batting_data, :teams_data # For TEST stubs
  attr_reader :result

  def initialize
    @batting_data = Set.new
    @teams_data = []
    @global_result_cache = nil
    @result = []

    initialize_pagination!
  end

  def load_data!
    # Set is a better data structure for computing the intersection of indexed data AND cleaning up duplicate elements
    @batting_data = CSV.read(File.join(__dir__, '../data/Batting.csv'), headers: true, encoding: 'UTF-8', header_converters: :symbol, converters: :all).to_set
    @teams_data = CSV.read(File.join(__dir__, '../data/Teams.csv'), headers: true, encoding: 'UTF-8', header_converters: :symbol, converters: :all)
  rescue StandardError => _e
    # falls back to initial state -> no ranking for ill formed or missing CSVs
  end

  def build_indexes!
    @batting_data_by_year_id = @batting_data.classify { |row| row[:yearid] }
    @batting_data_by_team_id = @batting_data.classify { |row| row[:teamid] }
    
    @teams_data_by_team_id = @teams_data.map { |item| OpenStruct.new(team_id: item[:teamid], team_name: item[:name]) }.uniq.group_by(&:team_id)
    @teams_data_by_team_name = @teams_data.map { |item| OpenStruct.new(team_id: item[:teamid], team_name: item[:name]) }.uniq.group_by(&:team_name)
  end

  def year?(year)
    @batting_data_by_year_id.key?(year.to_i)
  end

  def team?(team)
    @teams_data_by_team_name.key?(team)
  end

  def all_years
    @batting_data_by_year_id.keys.sort
  end

  def all_team_names
    @teams_data_by_team_name.keys.sort
  end

  def fetch_all
    @result = if !@global_result_cache.nil?
      @global_result_cache
    else
      sorted_ranking = get_batting_average_ranking_from(@batting_data)
      
      # CACHE global result to speed up things since we can't leverage indexes
      @global_result_cache = sorted_ranking
    end

    self
  end

  def fetch_by_year(year: nil)
    @result = get_batting_average_ranking_from(year_working_data(year))
    self
  end

  def fetch_by_team(team: nil)
    @result = get_batting_average_ranking_from(team_working_data(team))
    self
  end

  def fetch_by_team_and_year(team: nil, year: nil)
    @result = get_batting_average_ranking_from(year_working_data(year) & team_working_data(team))
    self
  end

  private

  def year_working_data(year)
    (@batting_data_by_year_id[year.to_i] || []).to_set
  end

  def team_working_data(team)
    team_id = @teams_data_by_team_name[team]&.at(0)&.team_id
    (@batting_data_by_team_id[team_id.to_s] || []).to_set
  end

  def get_batting_average_ranking_from(working_data = [])
    aggregated_data = aggregate_working_data(working_data)
    compute_sorted_batting_average(aggregated_data)
  end

  def aggregate_working_data(working_data)
    aggregated_data = {}

    working_data.each do |item|
      next unless [item[:playerid], item[:yearid], item[:h], item[:ab]].all?

      # LOAD
      aggregated_data[[item[:playerid], item[:yearid]]] ||= OpenStruct.new(team_ids: [], hits: 0, at_bats: 0)
      aggregated_data[[item[:playerid], item[:yearid]]].team_ids << item[:teamid] unless item[:teamid].nil?
      aggregated_data[[item[:playerid], item[:yearid]]].hits += item[:h]
      aggregated_data[[item[:playerid], item[:yearid]]].at_bats += item[:ab]
    end

    aggregated_data
  end

  def compute_sorted_batting_average(aggregated_data)
    sorted_ranking = SortedArrayBinary.new do |a, b|
      b[3] <=> a[3] # DESC order
    end

    aggregated_data.each do |key, struct|
      sorted_ranking << [
        key[0],
        key[1],
        @teams_data_by_team_id.values_at(*struct.team_ids.uniq).flatten.map(&:team_name).join(', '),
        struct.at_bats.positive? ? (struct.hits.to_f / struct.at_bats).round(3) : 0
      ]
    end

    sorted_ranking
  end
end
