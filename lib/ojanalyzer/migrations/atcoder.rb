require 'active_record'

class CreateAtCoderContests < ActiveRecord::Migration
  def self.up
    create_table :atcoder_contests do |t|
      t.string   :domain
      t.datetime :start_at
      t.datetime :finish_at
    end
  end
end

class CreateAtCoderSubmissions < ActiveRecord::Migration
  def self.up
    create_table :atcoder_submissions do |t|
      t.integer  :contest_id
      t.integer  :submission_id
      t.string   :problem_id
      t.string   :user_id
      t.string   :language
      t.string   :verdict
      t.datetime :submission_time

      t.index :contest_id
      t.index :user_id
      t.index :submission_time
    end
  end
end
