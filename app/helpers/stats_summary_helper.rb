module StatsSummaryHelper

  def render_stats_summary(job_stat)
    job_stat.attributes.with_indifferent_access.instance_eval do |stats|
      stats.slice(:total, :passed, :failed).merge(defective:
          stats[:aborting] + stats[:aborted] + stats[:defective])
    end.reject { |k, v| v == 0 }.reject { |k, v| k == 'total' }.sort_by do |attr, value|
      case attr
      when 'defective'
        0
      when 'failed'
        1
      when 'passed'
        3
      else
        10
      end
    end.map do |attr, value|
       render_haml <<-HAML.strip_heredoc
          %span.badge.job-stats-badge.#{attr}
            #{value}
          HAML
    end.join \
      render_haml <<-HAML.strip_heredoc
          %span
            %b :
        HAML
  end

  def render_haml(haml)
    ::Haml::Engine.new(haml).render
  end

end
