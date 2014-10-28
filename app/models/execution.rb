#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)j
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Execution < ActiveRecord::Base

  has_one :execution_stat
  has_one :execution_cache_signature

  before_create{self.id ||= SecureRandom.uuid}

  belongs_to :specification
  belongs_to :expanded_specification, class_name: 'Specification'

  has_and_belongs_to_many :tags 

  has_many :commits, primary_key: 'tree_id', foreign_key: 'tree_id'  #through: :tree
  has_many :execution_issues
  has_many :branches, through: :commits
  has_many :repositories, ->{reorder("").uniq}, through: :branches

  has_many :tasks #, foreign_key: [:specification_id,:tree_id]

  default_scope { order(created_at: :desc,tree_id: :asc,specification_id: :asc) }

  serialize :substituted_specification_data

  def tree_attachments
    TreeAttachment.where("path like '/#{tree_id}/%'")
  end

  def repository
    Repository.joins(branches: :commits).where("commits.tree_id  = ?",self.tree_id) \
      .reorder("branches.updated_at").first
  end

  ### deeper associations
  #def branches
  #  Branch.joins(commits: :tree).where("trees.id = ?",self.tree_id) \
  #    .reorder(name: :desc).select("DISTINCT branches.*")
  #end
  #def respositories
  #  Repository.joins(branches:  {commits: :tree}).where("trees.id = ?",self.tree_id) \
  #   .reorder(name: :asc,created_at: :desc).select("DISTINCT repositories.*")
  #end
  def trials
    Trial.joins(task: :execution) \
      .where("executions.tree_id = ?",tree_id)
  end
  ######################

  # a commit, rather arbitrary the most recent 
  # but git doesn't care as long it is referenced by a head 
  def commit 
    commits.reorder(updated_at: :desc).first
  end


  def accumulated_time
    trials.where.not(started_at: nil).where.not(finished_at: nil) \
      .select("date_part('epoch', SUM(finished_at - started_at)) as acc_time") \
      .reorder("").group("executions.tree_id").first[:acc_time]
  end

  def duration
    trials.reorder("") \
      .select("date_part('epoch', MAX(finished_at) - MIN(started_at)) duration") \
      .group("executions.tree_id").first[:duration]
  end

  def collect_from_specification hierarchy, keyword
    hierarchy.map{|x| x[keyword]}.reject(&:nil?).reduce(&:merge)
  end

  def create_tasks_and_trials
    Messaging.publish("execution.create-tasks-and-trials", {execution_id: id})
  end


  def add_strings_as_tags seq_of_strings 
    seq_of_strings \
      .map(&:strip).reject(&:blank?).compact.map{|name| Tag.tagify name} \
      .map{|tagified_name| Tag.find_or_create_by(tag: tagified_name)} \
      .each{|tag| self.add_tag tag}
  end

  def add_tag tag
    tags << tag unless tags.include? tag 
  end

  def sha1
    Digest::SHA1.hexdigest(id.to_s)
  end

  def to_s
    sha1
  end

end
