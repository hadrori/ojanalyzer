require 'active_record'
require 'activerecord-import'

class AtCoder::Submission < ActiveRecord::Base
  self.table_name = :atcoder_submissions
  belongs_to :atcoder_contest

  scope :submitted_in, -> (from, to) { where(submission_time: from..to) }
  scope :compiled, -> () { where.not(verdict: "CE").where.not(verdict: "NG") }
  scope :cpp, -> () { where("language like '%C++%'") }
end
