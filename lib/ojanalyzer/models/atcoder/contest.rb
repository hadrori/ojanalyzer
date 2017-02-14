class AtCoder::Contest < ActiveRecord::Base
  has_many :atcoder_submissions

  def contest_submissons
    submissions.submitted_in(self.start_at, self.finish_at)
  end

  def duration
    self.finish_at - self.start_at
  end
end