#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module CiderCI::JSONScripts
  class << self
    def dump(*args)
      JSON.dump *args
    end

    def load(*args)
      JSON.load(*args).instance_eval do
        self and Hash[self.sort_by { |k, v| v['order'] || 0 }]
      end
    end
  end
end

class Trial < ActiveRecord::Base
  self.primary_key = 'id'
  # serialize :result, JSON
  # serialize :scripts, CiderCI::JSONScripts
  before_create { self.id ||= SecureRandom.uuid }
  belongs_to :task
  belongs_to :executor
  has_many :trial_issues

  has_many :trial_attachments

  delegate :script, to: :task

  default_scope { reorder(created_at: :desc, id: :asc) }

end
