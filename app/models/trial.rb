#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Trial < ActiveRecord::Base
  belongs_to :task
  belongs_to :executor
  belongs_to :creator, foreign_key: :created_by, class_name: 'User'
  belongs_to :aborter, foreign_key: :aborted_by, class_name: 'User'
  has_many :trial_issues
  has_many :scripts

  has_many :trial_attachments

  default_scope { reorder(created_at: :desc, id: :asc) }
end
