#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Trial < ActiveRecord::Base
  self.primary_key= 'id'
  before_create{self.id ||= SecureRandom.uuid}
  belongs_to :task
  belongs_to :executor

  def trial_attachments
    TrialAttachment.where("path like '/#{id}/%'")
  end

  validates :state, inclusion: {in: Constants::TRIAL_STATES}

  delegate :script, to: :task

  default_scope{ reorder(created_at: :desc, id: :asc)}

  scope(:finished, lambda do
    where(state: ['passed','failed']).reorder(updated_at: :desc)
  end)

  scope :not_finished, lambda{
    where("state NOT IN ('passed','failed')").reorder(updated_at: :desc)} 
  
  scope :to_be_dispatched, lambda{
    where(state: 'pending').joins(task: :execution) \
    .reorder("executions.priority DESC", "executions.created_at DESC", "tasks.priority DESC", "tasks.created_at DESC")}

  scope :in_execution, lambda{
    where("trials.state IN ('dispatched','executing')")}

  scope :in_not_finished_timeout, lambda{
    not_finished.where(%[ trials.created_at <
      (now() - interval '#{TimeoutSettings.find.trial_end_state_timeout_minutes} Minutes')])}
  
  scope :in_dispatch_timeout, lambda{
    to_be_dispatched.reorder("").where(%[ trials.created_at <
      (now() - interval '#{TimeoutSettings.find.trial_dispatch_timeout_minutes} Minutes')])}

  scope :in_execution_timeout, lambda{
    in_execution().where(%[ trials.updated_at <
      (now() - interval '#{TimeoutSettings.find.trial_execution_timeout_minutes} Minutes')])}

  scope :with_scripts_to_clean, lambda{
    where("json_array_length(scripts) > 0")
    .where(%[ trials.created_at <
      (now() - interval '#{TimeoutSettings.find.trial_scripts_retention_time_days} Days')])}

end
