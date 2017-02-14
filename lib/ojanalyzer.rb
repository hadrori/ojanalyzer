require 'ojanalyzer/version'
require 'sqlite3'
require 'active_record'
require 'ojanalyzer/models/atcoder'
require 'ojanalyzer/crawler'

module OJAnalyzer
  def self.establish_databse_connection
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'data/ojanalyzer.db'
    )
  end
end
