require 'ojanalyzer/models/atcoder'
require 'faraday'
require 'faraday_middleware'
require 'nokogiri'

class OJAnalyzer::Crawlers::AtCoder
  def run
    fetch_contests
    AtCoder::Contest.all.each do |contest|
      puts "contest : #{contest.domain}"
      @conn = Faraday::Connection.new(url: "https://#{domain}.contest.atcoder.jp/submissions/all/") do |f|
        f.use FaradayMiddleware::FollowRedirects
        f.adapter Faraday.default_adapter
      end
      600.times do |page|
        puts "  page : #{page+1}" if page % 100 == 0
        try_counter = 0
        begin
          try_counter += 1
          fetch_submissions(contest, page+1)
        rescue Faraday::ConnectionFailed => e
          p e
          if try_counter < 10
            puts "  retry (#{try_counter-1})" 
            @conn = Faraday::Connection.new(url: "https://#{domain}.contest.atcoder.jp/submissions/all/") do |f|
              f.use FaradayMiddleware::FollowRedirects
              f.adapter Faraday.default_adapter
            end
            retry
          end
        rescue Faraday::TimeoutError => e
          p e
          if try_counter < 10
            puts "  retry (#{try_counter-1})" 
            @conn = Faraday::Connection.new(url: "https://#{domain}.contest.atcoder.jp/submissions/all/") do |f|
              f.use FaradayMiddleware::FollowRedirects
              f.adapter Faraday.default_adapter
            end
            retry
          end
        end
      end
    end
  end

  def fetch_submissions(contest, page)
    subs = submissions(@conn.get(page.to_s), contest)
    AtCoder::Submission.import subs, validate: false
  end

  def submissions(resp, contest)
    sub_ids = []
    subs = Nokogiri::HTML.parse(resp.body).xpath('/html/body/div/div/table/tbody').children.map { |tr|
      next if tr.name != 'tr'
      tds = tr.children.reject { |a| a.name != "td" }
      sub = Submission.new(
        contest_id: contest.id,
        submission_time: Time.parse(tds[0].children[0].children[0].to_s),
        user_id: user_id(tds),
        language: (tds[3].children[0].try(:text) || ""),
        verdict: (tds[6].children[0].try(:text) || ""),
        problem_id: problem_id(tds),
      )
      begin
        sub.submission_id = if sub.verdict == "AC"
                              submission_id(9, tds)
                            else
                              submission_id(7, tds)
                            end
      rescue Exception => e
        p e
        p sub
        sub.submission_id = -1
      end
      sub_ids << sub.submission_id
      sub
    }.compact
    reject_ids = AtCoder::Submission.where(submission_id: sub_ids).pluck(:submission_id)
    subs.reject { |sub| reject_ids.include?(sub.submission_id) }
  end

  def fetch_contests
    con = Faraday::Connection.new(url: 'http://kenkoooo.com/atcoder/json/') do |f|
      f.use FaradayMiddleware::FollowRedirects
      f.adapter Faraday.default_adapter
    end

    resp_hash = JSON.parse(con.get('contests.json').body)
    resp_hash.each do |contest|
      next unless AtCoder::Contest.where(domain: contest['id']).empty?
      AtCoder::Contest.create(
        domain: contest['id'],
        start_at: Time.parse(contest['start'] + ' +0000'),
        finish_at: Time.parse(contest['end'] + ' +0000')
      )
    end
  end

  private

  def submission_id(pos, tds)
    tds[pos].children[1].attributes["href"].value.scan(/\/submissions\/(.*)/).flatten.first.to_i
  end

  def problem_id(tds)
    tds[1].children[0].attributes["href"].value.scan(/tasks\/(.*)/).flatten.first
  end

  def user_id(tds)
    tds[2].children[0].attributes["href"].value.scan(/https:\/\/atcoder.jp\/user\/(.*)/).flatten.first
  end
end
