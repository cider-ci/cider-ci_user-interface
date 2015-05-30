#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Job < ActiveRecord::Base

  # serialize :result, JSON

  has_one :job_stat
  has_one :job_cache_signature

  before_create { self.id ||= SecureRandom.uuid }

  belongs_to :job_specification

  has_and_belongs_to_many :tags

  has_many :commits, primary_key: 'tree_id', foreign_key: 'tree_id'
  has_many :job_issues
  has_many :branches, through: :commits
  has_many :repositories, -> { reorder('').uniq }, through: :branches

  has_many :tasks

  has_many :trials, through: :tasks

  validates :state, inclusion: { in: Constants::JOB_STATES }

  default_scope { order(created_at: :desc, id: :asc) }

  serialize :substituted_job_specification_data

  def self.find_by_repo_branch_name(repo_name, branch_name, job_name)
    Job.joins(commits: { head_of_branches: :repository }) \
      .where('lower(jobs.name) = ?', job_name.downcase)
      .where('lower(branches.name) = ?', branch_name.downcase)
      .find_by('lower(repositories.name) =? ', repo_name.downcase)
  end

  def public_view_permission?
    repositories.where(public_view_permission: true).count > 0
  end

  def tree_attachments
    TreeAttachment.where("path like '/#{tree_id}/%'")
  end

  def accumulated_time
    trials.where.not(started_at: nil).where.not(finished_at: nil) \
      .select("date_part('epoch', SUM(finished_at - started_at)) as acc_time") \
      .reorder('').group('tasks.job_id').first[:acc_time]
  end

  def duration
    trials.reorder('') \
      .select("date_part('epoch', MAX(finished_at) - MIN(started_at)) duration") \
      .group('tasks.job_id').first[:duration]
  end

  def create_tasks_and_trials
    Messaging.publish('job.create-tasks-and-trials', job_id: id)
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
    stats = job_stat
    [(stats.failed > 0) ? stats.failed : '',
     (stats.failed > 0) ? '/' : '',
     stats.total].join('').squish
  end

  def result_summary?
    result && result['summary'].present? || false
  end

end
