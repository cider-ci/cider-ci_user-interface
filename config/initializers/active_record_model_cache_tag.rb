class ActiveRecord::Base
  def cache_signature(&block)
    if block_given?
      block.call(self)
    else
      self
    end.instance_eval do
     "[#{self.class.name}: #{id} - #{updated_at}]"
    end or Time.zone.now.iso8601(4)
  end
end
