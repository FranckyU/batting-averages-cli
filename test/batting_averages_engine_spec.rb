# encoding: UTF-8

require "minitest/autorun"
require_relative '../lib/batting_averages_engine'

describe BattingAveragesEngine do
  before do
    @engine = BattingAveragesEngine.new

    @batting_data = []
    @teams_data = []

    @test_matrix = {
      empty: [{
        batting_data: [],
        expected_ranking_result: []
      }],
      all: [{
        batting_data: [],
        expected_ranking_result: []
      }],
      filtered: [
        {
          filters: {year: '2020'},
          batting_data: [],
          expected_ranking_result: []
        },
        {
          filters: {team: 'TeamA'},
          batting_data: [],
          expected_ranking_result: []
        },
        {
          filters: {year: '2020', team: 'TeamA'},
          batting_data: [],
          expected_ranking_result: []
        }
      }],
      invalid: [
        {
          batting_data: [],
          expected_ranking_result: []
        }, 
        {
          batting_data: [],
          expected_ranking_result: []
        }
      ]
    }
  end

  it 'must return empty result at initial state' do
    expect(@engine.batting_data).must_be_empty
    expect(@engine.teams_data).must_be_empty
  end

  it 'returns all batting averages ranking' do

  end

  it 'should allow filtering' do

  end

  it 'must ignore invalid data' do

  end
end
