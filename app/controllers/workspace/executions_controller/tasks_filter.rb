#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Workspace::ExecutionsController::TasksFilter
  extend ActiveSupport::Concern

  def set_and_filter_tasks(params)
    @tasks_select_condition = (
      params[:tasks_select_condition] || :with_failed_trials).to_sym
    @name_substring_term = (params[:name_substring_term] || '')
    @page = params[:page]
    @tasks = @execution.tasks
    @tasks = case @tasks_select_condition
             when :all
               @tasks
             when :failed
               @tasks.where(state: 'failed')
             when :unpassed
               @tasks.where("state <> 'passed'")
             when :with_failed_trials
               @tasks.with_failed_trials
             end
    @tasks = if @name_substring_term.blank?
               @tasks
             else
               terms = @name_substring_term.split(/\s+OR\s+/)
               ilike_where = terms.map { ' tasks.name ILIKE ? ' }.join(' OR ')
               terms_matchers = terms.map { |term| "%#{term}%" }
               args = [ilike_where, terms_matchers].flatten
               @tasks.where(*args)
             end
    @tasks = @tasks.reorder(:name).page(params[:page])
    @tasks = @tasks.per(Integer(params[:per_page])) \
      unless params[:per_page].blank?
  end

end
