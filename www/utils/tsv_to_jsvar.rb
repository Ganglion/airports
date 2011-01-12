#!/usr/bin/env ruby

require 'rubygems'
require 'wukong'
require 'configliere' ; Configliere.use(:commandline, :env_var, :define)
require 'json'

class Mapper < Wukong::Streamer::RecordStreamer
  def process *args
    airport_code, lat, lng, passenger_degree, flights_degree, year = args
    yield [year, airport_code, lat, lng, passenger_degree, flights_degree]
  end
end

class Reducer < Wukong::Streamer::AccumulatingReducer

  def initialize *args
    super(*args)
    @var = {}
  end

  def start! year, *_
    @var[year.to_i] = []
  end

  # year, lat, lon, passenger_degree, flights_degree, airport_code
  def accumulate *args
    year, airport_code, lat, lng, passenger_degree, flights_degree = args
    @var[year.to_i] << {:lat => lat.to_f, :lng => lng.to_f, :passenger_degree => passenger_degree.to_i, :flights_degree => flights_degree.to_i, :airport_code => airport_code}
  end

  def finalize &blk
  end

  def after_stream
    File.open('data/degree_dist_geo.js', 'wb'){|f| f.puts "var degree_dist = #{JSON.pretty_generate(JSON.parse(@var.to_json))};"}
  end
end

Wukong::Script.new(Mapper, Reducer).run