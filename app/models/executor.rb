#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Executor < ActiveRecord::Base
  ONLINE_SQL_CONDITION = "last_ping_at > (now() - interval '3 Minutes')"

  has_many :trials
  has_one :executor_with_load, primary_key: 'id', foreign_key: 'id'

  self.primary_key = 'id'

  before_create { self.id ||= SecureRandom.uuid }

  default_scope { order(:name) }
  scope :enabled, -> { where(enabled: true) }
  scope :online, -> { where(ONLINE_SQL_CONDITION) }

  def online?
    !Executor.online.where(id: self.id).first.nil?
  end

  def to_s
    "#{name}"
  end

end
