#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class JobStat < ApplicationRecord
  self.primary_key = :job_id
  belongs_to :job
  def to_s
    attributes.values.to_s
  end
end
