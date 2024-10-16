class Public::SummaryController < ApplicationController
  include Concerns::SummaryBuilder
  include Concerns::SummaryRenderer

  def show
    # slight misuse or respond_to; put it in another way: why do I have to do
    # it this way and why is mime type negation not directly available resp.
    # documented?

    # make options available in lexical scope, same as in coffee/java-script
    options = nil

    respond_to do |format|
      format.html do
        options = { orientation: orientation_parameter || :vertical,
                    embedded: true }
      end
      format.svg do
        options = { orientation: orientation_parameter || :horizontal,
                    embedded: false }
      end
    end

    summary_properties = build_summary_properties(
      params[:repository_name], params[:branch_name],
      params[:job_names], options
    )

    @svg = render_summary_svg summary_properties

    if params.key?(:respond_with_200)
      render
    else
      render status: summary_properties[:status]
    end
  end

  def orientation_parameter
    params[:orientation].present? && params[:orientation]
  end
end
