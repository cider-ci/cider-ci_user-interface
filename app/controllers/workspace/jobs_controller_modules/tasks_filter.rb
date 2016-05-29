#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Workspace::JobsControllerModules::TasksFilter
  extend ActiveSupport::Concern

  def set_and_filter_tasks(params)
    @tasks = filter_tasks_by_substring_search \
      filter_tasks_by_condition set_per_page \
        @job.tasks.reorder(:name).page(params[:page])
  end

  def set_per_page(jobs)
    if params[:per_page].present?
      jobs.per(Integer(params[:per_page]))
    else
      jobs
    end
  end

  def filter_tasks_by_substring_search(tasks)
    name_substring_term = (params[:name_substring_term] || '')
    if name_substring_term.blank?
      tasks
    else
      terms = name_substring_term.split(/\s+OR\s+/)
      ilike_where = terms.map { ' tasks.name ILIKE ? ' }.join(' OR ')
      terms_matchers = terms.map { |term| "%#{term}%" }
      args = [ilike_where, terms_matchers].flatten
      tasks.where(*args)
    end
  end

  def filter_tasks_by_condition(tasks)
    # @tasks_select_condition must be an instance var!; it is used in views
    @tasks_select_condition = tasks_select_condition
    case @tasks_select_condition
    when :all
      tasks
    else
      tasks.with_unpassed_trials
    end
  end

  def tasks_select_condition
    if params[:tasks_select_condition].present?
      params[:tasks_select_condition].to_sym
    else
      case @job.state
      when 'passed'
        :all
      else
        :with_unpassed_trials
      end
    end
  end

end
