class ActiveRecord::Base
  def cache_signature(&_block)
    if block_given?
      yield self
    else
      self
    end.instance_eval do
      "[#{self.class.name}: #{id} - #{attributes_before_type_cast["updated_at"]}]"
    end or Time.zone.now.iso8601(4)
  end
end
