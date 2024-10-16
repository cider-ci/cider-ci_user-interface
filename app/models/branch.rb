#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Branch < ApplicationRecord
  self.primary_key = :id

  belongs_to :repository
  has_and_belongs_to_many :commits
  belongs_to :current_commit, class_name: "Commit", foreign_key: "current_commit_id"

  def jobs
    Job.joins(commits: :head_of_branches).where("branches.id = ?", id)
  end

  default_scope { order(name: :asc) }

  before_create do
    self.id ||= SecureRandom.uuid
  end

  def to_s
    name
  end
end
