#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Executor < ApplicationRecord
  ONLINE_SQL_CONDITION = "last_ping_at > (now() - interval '3 Minutes')".freeze

  has_many :trials
  has_many :executor_issues
  has_one :executor_with_load, primary_key: "id", foreign_key: "id"

  self.primary_key = "id"

  before_create { self.id ||= SecureRandom.uuid }

  default_scope { order(:name) }
  scope :enabled, -> { where(enabled: true) }
  scope :online, -> { where(ONLINE_SQL_CONDITION) }

  def online?
    !Executor.online.find_by(id: self.id).nil?
  end

  def auth_password
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha1"), Settings[:secret], name
    )
  end

  delegate :to_s, to: :name
end
