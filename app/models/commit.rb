#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Commit < ActiveRecord::Base
  self.primary_key = 'id'

  has_and_belongs_to_many :branches
  has_and_belongs_to_many :children, class_name: 'Commit',
                                     join_table: 'commit_arcs',
                                     association_foreign_key: 'child_id',
                                     foreign_key: 'parent_id'
  has_and_belongs_to_many :parents, class_name: 'Commit',
                                    join_table: 'commit_arcs',
                                    foreign_key: 'child_id',
                                    association_foreign_key: 'parent_id'
  has_one :commit_cache_signature
  has_many :head_of_branches, class_name: 'Branch',
                              foreign_key: 'current_commit_id'
  has_many :executions, primary_key: 'tree_id', foreign_key: 'tree_id'

  default_scope { order(committer_date: :desc, created_at: :desc, id: :asc) }

  has_many :repositories, through: :branches

end
