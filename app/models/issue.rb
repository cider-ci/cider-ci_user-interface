module Issue
  extend ActiveSupport::Concern

  TYPE_BS_MAP = { error: :danger, warning: :warning }.freeze

  included do
    self.inheritance_column = false
  end

  def bootstrap_type
    TYPE_BS_MAP[type.to_sym]
  end
end
