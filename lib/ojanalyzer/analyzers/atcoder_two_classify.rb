require 'ojanalyzer/models/atcoder'
require 'ojanalyzer/analyzers/feature_extracter'

class AtCoderTwoClassify
  FROM = Time.parse('2016-01-01 00:00 +0000')
  DURATION = 6.months

  def initialize
    @feature = FeatureExtracter.new
  end

  def prepare_user(user)
    file_paths = AtCoder::Submission.compiled.cpp.where(user_id: user).submitted_in(FROM, FROM+DURATION).map { |sub|
      if valid_code?(atcoder_sub_path(sub))
        atcoder_sub_path(sub)
      else
        nil
      end
    }.compact
  end

  def prepare_others(user)
    relation = AtCoder::Submission.compiled.cpp.submitted_in(FROM, FROM+DURATION)
    target_users = relation.where.not(user_id: user).group(:user_id).count.to_a.reject{|a,b| b < 300}.map(&:first)
    relation.where(user_id: target_users).map { |sub|
      if valid_code?(atcoder_sub_path(sub))
        atcoder_sub_path(sub)
      else
        nil
      end
    }.compact
  end

  def run(user = "hadrori", from = FROM, duration = DURATION)
    time_str = Time.now.strftime("%Y%m%d%H%M%S")
    ofile_name = "#{user}-#{time_str}.csv"
    user_file_paths = prepare_user(user)
    others_file_paths = prepare_others(user).sample(user_file_paths.size)
    count = 0
    File.open(ofile_name, 'w') do |file|
      user_file_paths.each do |file_path|
        count += 1
        puts "count : #{count}" if count % 100 == 0
        data = get_data(file_path, 1)
        file.puts data.map(&:to_s).join(',') if data.present?
      end
      others_file_paths.each do |file_path|
        count += 1
        puts "count : #{count}" if count % 100 == 0
        data = get_data(file_path, 0)
        file.puts data.map(&:to_s).join(',') if data.present?
      end
    end

    puts "Wrote to #{ofile_name}"
  end

  def get_data(file_path, flag)
    return nil unless valid_code?(file_path)
    [flag] + @feature.run(file_path)
  end

  def atcoder_sub_path(sub)
    "./data/codes/atcoder/#{sub.submission_id}.cpp"
  end

  def valid_code?(file_path)
    File.exist?(file_path)
  end
end
