require "ojanalyzer/version"

class OJAnalyzer
  def initialize
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'ojanalyzer.db'
    )
  end
end
