#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Commit < ActiveRecord::Base
  self.primary_key = 'id'

  has_and_belongs_to_many :branches
  has_and_belongs_to_many :children, class_name: 'Commit', join_table: 'commit_arcs', association_foreign_key: 'child_id', foreign_key: 'parent_id'
  has_and_belongs_to_many :parents, class_name: 'Commit', join_table: 'commit_arcs', foreign_key: 'child_id', association_foreign_key: 'parent_id'
  has_one :commit_cache_signature
  has_many :head_of_branches, class_name: 'Branch', foreign_key: 'current_commit_id'
  has_many :executions, primary_key: 'tree_id', foreign_key: 'tree_id'  #through: :tree 


  default_scope{order(committer_date: :desc,created_at: :desc,id: :asc)}

  has_many :repositories, through: :branches

  #def repositories
  #  Repository.joins(branches: :commits).where("commits.id = ?",id).select("DISTINCT repositories.*")
  #end

  def with_ancestors 
    # we should be avoid the subquery "id IN" if we 
    # patch AR to include a WITH statement
    # REMARK: there seems to be with_recursive support in arel; how to use it? 
    Commit.where(" commits.id IN (
      WITH RECURSIVE ancestors AS
      (
        SELECT * FROM commits WHERE ID = ?
        UNION 
        SELECT commits.* 
          FROM ancestors, commit_arcs, commits
          WHERE TRUE
          AND ancestors.id = commit_arcs.child_id
          AND commit_arcs.parent_id = commits.id
      )
      SELECT id FROM ancestors)", id).reorder(committer_date: :desc)
  end

  def with_descendants
    Commit.where(" commits.id IN (
      WITH RECURSIVE descendants AS
      (
        SELECT * FROM commits WHERE ID = ?
        UNION 
        SELECT commits.* 
          FROM descendants, commit_arcs, commits
          WHERE TRUE
          AND descendants.id = commit_arcs.parent_id
          AND commit_arcs.child_id = commits.id
      )
      SELECT id FROM descendants)", id).reorder(committer_date: :desc)
  end

end
