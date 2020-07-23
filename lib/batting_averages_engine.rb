# encoding: UTF-8

require 'csv'
require 'ostruct'
require 'set'
require 'sorted_array_binary'

require_relative 'utils/paginator'

class BattingAveragesEngine
  include Utils::Paginator

  attr_accessor :batting_data, :teams_data, :limit # For TEST stub & limit extension

  def initialize
    @batting_data = []
    @teams_data = []

    @global_result_cache = nil

    initialize_pagination!
  end

  # EXTRACT
  def fetch_data!
    @batting_data = CSV.read(File.join(__dir__, "../data/Batting.csv"), headers: true, encoding: 'UTF-8', header_converters: :symbol, converters: :all)
    @teams_data = CSV.read(File.join(__dir__, "../data/Teams.csv"), headers: true, encoding: 'UTF-8', header_converters: :symbol, converters: :all)
  rescue
    # falls back to initial state -> no ranking for ill formed or missing CSVs
  end

  # TRANSFORM
  def build_indexes!
    @batting_data_by_year_id = @batting_data.group_by{|row| row[:yearid]}
    @batting_data_by_team_id = @batting_data.group_by{|row| row[:teamid]}
    
    @teams_data_by_team_id = @teams_data.map{|item| OpenStruct.new(team_id: item[:teamid], team_name: item[:name])}.uniq.group_by(&:team_id)
    @teams_data_by_team_name = @teams_data.map{|item| OpenStruct.new(team_id: item[:teamid], team_name: item[:name])}.uniq.group_by(&:team_name)
  end

  def has_year?(year)
    @batting_data_by_year_id.has_key?(year.to_i)
  end

  def has_team?(team)
    @teams_data_by_team_name.has_key?(team)
  end

  def all_years
    @batting_data_by_year_id.keys.sort
  end

  def all_team_names
    @teams_data_by_team_name.keys.sort
  end

  def by(team: nil, year: nil)
    result = if [team, year].none? && !@global_result_cache.nil?
      @global_result_cache
    else
      # TRANSFORM + CLEANUP
      # Set is a better data structure for computing the intersection of indexed data AND cleaning up duplicate elements
      working_data = @batting_data.to_set
      working_data = working_data & (@batting_data_by_year_id[year.to_i] || []).to_set unless year.nil?
      
      unless team.nil?
        team_id = @teams_data_by_team_name[team]&.at(0)&.team_id
        working_data = working_data & (@batting_data_by_team_id[team_id.to_s] || []).to_set unless team_id.nil?
      end

      if working_data.empty?
        return [] 
      end

      res = {}

      working_data.each do |item|
        # CLEANUP
        next unless [item[:playerid], item[:yearid], item[:h], item[:ab]].all?

        # LOAD
        res[[item[:playerid], item[:yearid]]] ||= OpenStruct.new(team_ids: [], hits: 0, at_bats: 0)
        res[[item[:playerid], item[:yearid]]].team_ids << item[:teamid] unless item[:teamid].nil?
        res[[item[:playerid], item[:yearid]]].hits += item[:h]
        res[[item[:playerid], item[:yearid]]].at_bats += item[:ab]
      end

      sorted_ranking = SortedArrayBinary.new do |a, b| 
        b[3] <=> a[3] # DESC order
      end

      res.each do |key, struct|
        sorted_ranking << [
          key[0],
          key[1],
          @teams_data_by_team_id.values_at(*struct.team_ids.uniq).flatten.map(&:team_name).join(', '),
          struct.at_bats > 0 ? (struct.hits.to_f/struct.at_bats).round(3) : 0
        ]
      end

      # CACHE global result to speed up things since we can't leverage indexes
      @global_result_cache = sorted_ranking if [year, team].none?

      sorted_ranking
    end

    # update_pagination
    @total_count = result.length

    # OUTPUT
    result[@offset, @per_page]
  end
  alias_method :get_all, :by
end