#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module ApplicationHelper
  def convert_anygit_to_https_url(url)
    url
      .gsub(/^\w*@?((\w+\.)+\w+):/, 'https://\\1/')
      .gsub(/\.git$/, "")
      .gsub(/\/$/, "")
  end

  def gravatar_url(email)
    hs = Digest::MD5.hexdigest email.squish.downcase
    "https://www.gravatar.com/avatar/#{hs}?s=20&d=retro"
  end

  def form_group(label, opts = {}, &)
    control_id = opts[:control_id] || SecureRandom.uuid
    render "form_group", label: label,
                         control_id: control_id,
                         cols_label: opts[:cols_label] || 3,
                         label_class: opts[:label_class] || "",
                         cols_control: opts[:cols_control] || 5,
                         block_output: capture(opts.merge(control_id: control_id), &)
  end

  def git_icon_for_url(url)
    if /github\.com/.match?(url)
      "fa fa-github"
    elsif /bitbucket\.org/.match?(url)
      "fa fa-bitbucket"
    else
      "fa fa-git"
    end
  end

  def icon_class_for_state(state)
    case state
    when "aborted"
      "icon-aborted"
    when "aborting"
      "icon-aborting"
    when "defective"
      "icon-defective"
    when "executing", "dispatching"
      "icon-executing"
    when "failed"
      "icon-failed"
    when "passed"
      "icon-passed"
    when "pending"
      "icon-pending"
    when "skipped"
      "icon-skipped"
    when "waiting"
      "icon-waiting"
    else
      "icon-unknown"
    end
  end

  def label_for_state(state)
    render "label_for_state", state: state
  end

  def link_to_commit(commit)
    render partial: "link_to_commit", locals: { commit: commit }
  end

  def label_class_for_state(state)
    case state
    when "failed"
      "label-failed"
    when "passed"
      "label-passed"
    when "pending", "waiting"
      "label-pending"
    when "executing", "dispatching"
      "label-executing"
    when "aborted", "aborting", "defective", "skipped"
      "label-warning"
    else
      "label-default"
    end
  end

  def markdown(source)
    Kramdown::Document.new(source).to_html.html_safe
  rescue Exception => e
    Rails.logger.error Formatter.exception_to_log_s e
    "Markdown render error!"
  end

  def render_executor_row(executor, &)
    render "executor_row", executor: executor, block_output: capture(&)
  end

  def render_summary_svgbox(view_params)
    # TODO: seems not to be used and should not work anyways ; delete?
    capture(
      render(partial: "summary_svgbox", locals: view_params)
    )
  end

  def stylesheet_chooser
    case current_user&.ui_theme
    when "cider"
      "cider"
    when "bootstrap"
      "bootstrap-plain"
    else
      "bootstrap-plain"
    end
  end
end
