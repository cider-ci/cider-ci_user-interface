module Concerns
  module SummaryRenderer
    extend ActiveSupport::Concern

    def render_summary_svg(summary_properties)
      @horizontal = summary_properties[:orientation].to_s == 'horizontal'
      embedded = summary_properties[:embedded]
      @base_height = summary_properties[:base_height] || 20
      @base_width = summary_properties[:base_width] || 300
      base_font_size = summary_properties[:base_font_size] || 11
      font_factor = summary_properties[:font_factor] || 1.2
      @font_size = (base_font_size * font_factor)
      @font_name = 'DejaVu Sans'

      @xoffset = 0
      @yoffset = 0

      info_boxes = render_info_boxes summary_properties
      job_boxes = render_job_boxes summary_properties

      total_width = @horizontal ? @xoffset : 300
      total_height = @horizontal ? @base_height : @yoffset

      render_to_string partial: '/public/summary/summary_svg', locals: {
        embedded: embedded, font_size: @font_size, width: total_width,
        height: total_height,
        boxes: [info_boxes, job_boxes].flatten.compact
      }
    end

    def render_info_boxes(summary_properties)
      [:host, :git, :failed].map do |prefix|
        symbol = "#{prefix}_info_text".to_sym
        if summary_properties[symbol].present?
          render_info_box(prefix, summary_properties[symbol])
        end
      end
    end

    def render_info_box(prefix, text)
      width = compute_box_width text
      height = @base_height
      svg = render_to_string partial: '/public/summary/info_svgbox', locals: {
        xoffset: @xoffset, yoffset: @yoffset, height: height,
        width: width, prefix: prefix, text: text }
      @xoffset += (@horizontal ? width : 0)
      @yoffset += (@horizontal ? 0 : height)
      svg
    end

    def render_job_boxes(summary_properties)
      (summary_properties[:jobs] || []) \
        .map.with_index { |e, i| render_job_box e, i }
    end

    def render_job_box(job, i)
      text = job[:text]
      width = compute_box_width text, bold: true
      height = @horizontal ? @base_height : (@base_height * 1.5).ceil
      yfont = (14.0 / @base_height * height)
      svg = render_to_string partial: '/public/summary/job_svgbox', locals: {
        xoffset: @xoffset, yoffset: @yoffset, height: height,
        width: width, text: text, job: job, i: i, yfont: yfont }
      @xoffset += (@horizontal ? width : 0)
      @yoffset += (@horizontal ? 0 : height)
      svg
    end

    def compute_box_width(text, bold = false)
      if @horizontal
        FontMetrics.text_width(
          text, [@font_name, (bold ? 1 : 0), @font_size]) * 1.2
      else
        @base_width
      end
    end

  end
end
