require 'ojanalyzer/version'
require 'sqlite3'
require 'active_record'

class OJAnalyzer
  def initialize
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'ojanalyzer.db'
    )
  end
end
