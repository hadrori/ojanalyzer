require 'ojanalyzer/models/atcoder'
require 'faraday'
require 'faraday_middleware'
require 'nokogiri'

class OJAnalyzer::Crawler::AtCoder
  def run
    fetch_contests
    fetch_submissions
    fetch_cpp_code
    puts "====== Finished ======"
  end

  def fetch_submissions
    puts "====== Get Submission Info ======"
    AtCoder::Contest.all.each do |contest|
      domain = contest.domain
      puts "contest : #{domain}"
      base_url = "https://#{domain}.contest.atcoder.jp/submissions/all/"
      connect(base_url)

      600.times do |page|
        puts "  page : #{page}" if page % 100 == 0
        with_retry(base_url) do
          fetch_submissions_by_page(contest, page+1)
        end
      end
    end
  end

  def fetch_cpp_code
    puts "====== Get C++ Code ======"
    FileUtils.mkdir_p('./data/codes/atcoder') unless Dir.exists?('./data/codes/atcoder')
    AtCoder::Contest.all.each do |contest|
      domain = contest.domain
      puts "contest : #{domain}"
      contest.submissions.compiled.cpp.each do |sub|
        with_retry do
          save_code(sub, domain)
        end
      end
    end
  end

  def fetch_submissions_by_page(contest, page)
    subs = submissions(con.get(page.to_s), contest)
    AtCoder::Submission.import subs, validate: false
  end

  def submissions(resp, contest)
    sub_ids = []
    subs = Nokogiri::HTML.parse(resp.body).xpath('/html/body/div/div/table/tbody').children.map { |tr|
      next if tr.name != 'tr'
      tds = tr.children.reject { |a| a.name != "td" }
      sub = AtCoder::Submission.new(
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
    puts "====== Update Contest Info ======"
    connect('http://kenkoooo.com/atcoder/json/')

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

  def connect(url)
    @con = Faraday::Connection.new(url: url) do |f|
      f.use FaradayMiddleware::FollowRedirects
      f.adapter Faraday.default_adapter
    end
  end

  def con
    @con
  end

  def submission_id(pos, tds)
    tds[pos].children[1].attributes["href"].value.scan(/\/submissions\/(.*)/).flatten.first.to_i
  end

  def problem_id(tds)
    tds[1].children[0].attributes["href"].value.scan(/tasks\/(.*)/).flatten.first
  end

  def user_id(tds)
    tds[2].children[0].attributes["href"].value.scan(/https:\/\/atcoder.jp\/user\/(.*)/).flatten.first
  end

  def save_code(sub, domain)
    connect("https://#{domain}.contest.atcoder.jp/submissions")

    doc = Nokogiri::HTML.parse(con.get("#{sub.submission_id}").body, nil, nil)
    code = doc.xpath('//pre[@class="prettyprint linenums"]').first.try(:inner_text)

    if code
      File.open("./data/codes/atcoder/#{sub.submission_id}.cpp", "w") do |f|
        f.write(code)
      end
    end
  end

  def with_retry(url = nil)
    try_counter = 0
    begin
      try_counter += 1
      yield
    rescue Faraday::ConnectionFailed => e
      p e
      if try_counter < 10
        puts "  retry (#{try_counter-1})"
        connect(url) if url
        retry
      end
    rescue Faraday::TimeoutError => e
      p e
      if try_counter < 10
        puts "  retry (#{try_counter-1})" 
        connect(url) if url
        retry
      end
    end
  end
end
