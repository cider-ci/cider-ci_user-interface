#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Script < ApplicationRecord
  belongs_to :trial

  default_scope { reorder(started_at: :asc, finished_at: :asc, key: :asc, name: :asc) }
end
