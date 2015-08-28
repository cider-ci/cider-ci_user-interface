class ActiveRecord::Relation
  def apply(ar_chain)
    ar_chain.call(self)
  end
end
