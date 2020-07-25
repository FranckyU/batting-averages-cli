# encoding: UTF-8

require "minitest/autorun"
require_relative '../lib/batting_averages_engine'

describe BattingAveragesEngine do
  before do
    @engine = BattingAveragesEngine.new

    default_batting_data = Set.new([
      {yearid: 2019, teamid: 'A', playerid: 'jhn1', h: 1, ab: 10}, # BA = 1/10
      {yearid: 2019, teamid: 'B', playerid: 'bob42', h: 3, ab: 10}, # BA = 3/10
      {yearid: 2019, teamid: 'A', playerid: 'alice8', h: 5, ab: 10}, # BA = 1/2
      {yearid: 2019, teamid: 'B', playerid: 'malory9', h: 4, ab: 5}, # BA = 4/5

      {yearid: 2020, teamid: 'A', playerid: 'jhn1', h: 1, ab: 10},
      {yearid: 2020, teamid: 'A', playerid: 'bob42', h: 9, ab: 10}, # bob plays in 2 teams
      {yearid: 2020, teamid: 'B', playerid: 'bob42', h: 7, ab: 8},
      {yearid: 2020, teamid: 'B', playerid: 'malory9', h: 4, ab: 5},

      {yearid: 2020, teamid: nil, playerid: 'xavi22', h: 3, ab: 3} # BA = 1
    ])

    invalid_batting_data = Set.new([
      {teamid: 'A', playerid: 'jhn1', h: 10, ab: 10}, # BA = 1
      {yearid: 2019, teamid: nil, playerid: nil, h: 10, ab: 10},
      {yearid: 2019, teamid: 'A', playerid: 'scott0', h: 10, ab: nil},
      {yearid: 2019, teamid: 'B', playerid: 'hugh', h: nil, ab: 10},
      {yearid: 2019, teamid: 'B', playerid: 'marcello'}
    ])

    @teams_data = [
      {teamid: 'A', name: 'Team A'},
      {teamid: 'B', name: 'Team B'}
    ]

    @test_matrix = {
      empty: [
        {
          batting_data: Set.new,
          expected_ranking_result: []
        }
      ],
      all: [
        {
          batting_data: default_batting_data,
          expected_ranking_result: [
            ['xavi22', 2020, '', 1.0],

            ['bob42', 2020, 'Team A, Team B', 0.889],

            ['malory9', 2019, 'Team B', 0.8],
            ['malory9', 2020, 'Team B', 0.8],

            ['alice8', 2019, 'Team A', 0.5],
            
            ['bob42', 2019, 'Team B', 0.3],

            ['jhn1', 2019, 'Team A', 0.1],
            ['jhn1', 2020, 'Team A', 0.1],
          ]
        }
      ],
      filtered: [
        {
          filters: {year: 2020},
          batting_data: default_batting_data,
          expected_ranking_result: [
            ['xavi22', 2020, '', 1.0],
            ['bob42', 2020, 'Team A, Team B', 0.889],
            ['malory9', 2020, 'Team B', 0.8],
            ['jhn1', 2020, 'Team A', 0.1],
          ]
        },
        {
          filters: {team: 'Team A'},
          batting_data: default_batting_data,
          expected_ranking_result: [
            ['bob42', 2020, 'Team A', 0.9],
            ['alice8', 2019, 'Team A', 0.5],
            ['jhn1', 2019, 'Team A', 0.1],
            ['jhn1', 2020, 'Team A', 0.1],
          ]
        },
        {
          filters: {year: 2020, team: 'Team A'},
          batting_data: default_batting_data,
          expected_ranking_result: [
            ['bob42', 2020, 'Team A', 0.9],
            ['jhn1', 2020, 'Team A', 0.1],
          ]
        }
      ],
      with_invalid: [
        {
          batting_data: invalid_batting_data+default_batting_data,
          expected_ranking_result: [
            ['xavi22', 2020, '', 1.0],

            ['bob42', 2020, 'Team A, Team B', 0.889],

            ['malory9', 2019, 'Team B', 0.8],
            ['malory9', 2020, 'Team B', 0.8],

            ['alice8', 2019, 'Team A', 0.5],
            
            ['bob42', 2019, 'Team B', 0.3],

            ['jhn1', 2019, 'Team A', 0.1],
            ['jhn1', 2020, 'Team A', 0.1],
          ]
        }
      ]
    }
  end

  it 'must return empty result at initial state' do
    expect(@engine.batting_data).must_be_empty
    expect(@engine.teams_data).must_be_empty
  end

  it 'must return empty result when fed no batting data' do
    # eq. of @engine.fetch_data!
    @engine.batting_data = @test_matrix[:empty][0][:batting_data]
    @engine.teams_data = @teams_data

    @engine.build_indexes!

    expect(@engine.get_all).must_be_empty
  end

  it 'returns all batting averages ranking' do
    # eq. of @engine.fetch_data!
    @engine.batting_data = @test_matrix[:all][0][:batting_data]
    @engine.teams_data = @teams_data

    @engine.build_indexes!

    expect(@engine.get_all).must_equal(@test_matrix[:all][0][:expected_ranking_result])
  end

  it 'should allow filtering' do
    @test_matrix[:filtered].each do |hash|
      # eq. of @engine.fetch_data!
      @engine.batting_data = hash[:batting_data]
      @engine.teams_data = @teams_data

      @engine.build_indexes!

      expect(@engine.by(**hash[:filters])).must_equal(hash[:expected_ranking_result])
    end
  end

  it 'must ignore invalid data' do
    # eq. of @engine.fetch_data!
    @engine.batting_data = @test_matrix[:with_invalid][0][:batting_data]
    @engine.teams_data = @teams_data

    @engine.build_indexes!

    expect(@engine.get_all).must_equal(@test_matrix[:with_invalid][0][:expected_ranking_result])
  end
end
