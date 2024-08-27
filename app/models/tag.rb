#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Tag < ApplicationRecord
  has_and_belongs_to_many :jobs

  def self.tagify(s)
    s.downcase.gsub(/[^0-9a-z\-\.]/i, '-').gsub(/-+/, '-')
  end
end
