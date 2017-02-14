module OJAnalyzer::Crawler
end

Dir[File.dirname(__FILE__) + '/crawlers/*.rb'].each {|file| require file }
