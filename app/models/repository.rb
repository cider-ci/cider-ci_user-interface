#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Repository < ActiveRecord::Base
  has_many :branches, dependent: :destroy

  before_validation on: :create do
    raise 'origin_uri is required' if self.origin_uri.blank?
    self.id = UUIDTools::UUID.sha1_create(UUIDTools::UUID_URL_NAMESPACE,
                                          self.origin_uri).to_s
    self.name ||= self.id
  end

  ######################## Scopes and methods returning AR ####################

  default_scope { reorder(name: :asc, id: :asc) }

  ######################## Other stuff ########################################

  def to_s
    name
  end

end
