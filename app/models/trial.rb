#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Trial < ActiveRecord::Base
  self.primary_key = 'id'
  before_create { self.id ||= SecureRandom.uuid }
  belongs_to :task
  belongs_to :executor

  def trial_attachments
    TrialAttachment.where("path like '/#{id}/%'")
  end

  validates :state, inclusion: { in: Constants::TRIAL_STATES }

  delegate :script, to: :task

  default_scope { reorder(created_at: :desc, id: :asc) }

end
