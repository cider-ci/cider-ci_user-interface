module Concerns
  module JsonForAutocomplete
    extend ActiveSupport::Concern

    def build_single_column_json_for_autocomplete(model, column_name)
      model.reorder("#{column_name} ASC").instance_exec(params) do |params|
        if (term = params[:term]).blank?
          self
        else
          where("#{column_name} ilike ?", "#{term}%")
        end
      end.distinct.limit(25).pluck(column_name)
    end

  end
end
