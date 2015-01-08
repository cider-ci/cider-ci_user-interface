#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Execution < ActiveRecord::Base

  serialize :result, JSON

  has_one :execution_stat
  has_one :execution_cache_signature

  before_create { self.id ||= SecureRandom.uuid }

  belongs_to :specification
  belongs_to :expanded_specification, class_name: 'Specification'

  has_and_belongs_to_many :tags

  has_many :commits, primary_key: 'tree_id', foreign_key: 'tree_id'
  has_many :execution_issues
  has_many :branches, through: :commits
  has_many :repositories, -> { reorder('').uniq }, through: :branches

  has_many :tasks # , foreign_key: [:specification_id,:tree_id]

  validates :state, inclusion: { in: Constants::EXECUTION_STATES }

  default_scope { order(created_at: :desc, tree_id: :asc, specification_id: :asc) }

  serialize :substituted_specification_data

  def self.find_by_repo_branch_name(repo_name, branch_name, execution_name)
    Execution.joins(commits: { head_of_branches: :repository }) \
      .where('lower(executions.name) = ?', execution_name.downcase)
      .where('lower(branches.name) = ?', branch_name.downcase)
      .where('lower(repositories.name) =? ', repo_name.downcase)
      .first
  end

  def public_view_permission?
    repositories.where(public_view_permission: true).count > 0
  end

  def tree_attachments
    TreeAttachment.where("path like '/#{tree_id}/%'")
  end

  def trials
    Trial.joins(task: :execution).where('executions.tree_id = ?', tree_id)
  end

  def accumulated_time
    trials.where.not(started_at: nil).where.not(finished_at: nil) \
      .select("date_part('epoch', SUM(finished_at - started_at)) as acc_time") \
      .reorder('').group('executions.tree_id').first[:acc_time]
  end

  def duration
    trials.reorder('') \
      .select("date_part('epoch', MAX(finished_at) - MIN(started_at)) duration") \
      .group('executions.tree_id').first[:duration]
  end

  def create_tasks_and_trials
    Messaging.publish('execution.create-tasks-and-trials', execution_id: id)
  end

  def add_strings_as_tags(seq_of_strings)
    seq_of_strings \
      .map(&:strip).reject(&:blank?).compact.map { |name| Tag.tagify name } \
      .map { |tagified_name| Tag.find_or_create_by(tag: tagified_name) } \
      .each { |tag| self.add_tag tag }
  end

  def add_tag(tag)
    tags << tag unless tags.include? tag
  end

  def sha1
    Digest::SHA1.hexdigest(id.to_s)
  end

  def to_s
    sha1
  end

  def stats_summary
    stats = execution_stat
    [(stats.failed > 0) ?  stats.failed : '',
     (stats.failed > 0) ? '/' : '',
     stats.total].join('').squish
  end

  def result_summary?
    result && result['summary'].present? || false
  end

end
