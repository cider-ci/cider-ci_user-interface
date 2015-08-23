class ActiveRecord::Relation
  def filter_by(filter)
    filter.call(self)
  end
end
