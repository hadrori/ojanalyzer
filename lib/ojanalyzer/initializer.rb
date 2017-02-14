require 'migrations/atcoder.rb'
require 'sqlite3'
require 'active_record'

class OJAnalyzer::Initializer
  def initialize
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'ojanalyzer.db'
    )
  end

  def run
    CreateAtCoderContests.up
    CreateAtCoderSubmissions.up
  end
end
