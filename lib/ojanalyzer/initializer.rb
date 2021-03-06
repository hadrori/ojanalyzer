require 'ojanalyzer/migrations/atcoder'
require 'sqlite3'
require 'active_record'

class OJAnalyzer::Initializer
  def run
    drop_database
    create_database
    create_tables
  end

  def drop_database
    if File.exist?('data/ojanalyzer.db')
      puts "-- delete database"
      File.delete('data/ojanalyzer.db')
    end
  end

  def create_database
    puts "-- create database"
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'data/ojanalyzer.db'
    )
  end

  def create_tables
    CreateAtCoderContests.up
    CreateAtCoderSubmissions.up
  end
end
