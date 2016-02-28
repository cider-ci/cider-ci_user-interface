#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class User < ActiveRecord::Base
  has_secure_password validations: false
  has_many :email_addresses, -> { order(email_address: :asc) }

  after_create :create_password_if_blank

  def to_s
    "#{name} [#{login}]".squish
  end

  validates :login, presence: true

  default_scope { order(:login) }

  scope :most_recent, -> { reorder(updated_at: :desc) }

  def self.users?
    User.count > 0
  end

  def self.admins?
    User.where(is_admin: true).count > 0
  end

  def create_password_if_blank
    if self.password_digest.blank?
      self.password = SecureRandom.base64(24)
      self.save
    end
  end

end
