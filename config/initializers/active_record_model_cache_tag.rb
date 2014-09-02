class ActiveRecord::Base
  def cache_signature &block
    if block_given?
      block.call(self)
    else
      self
    end.instance_eval {
     "[#{self.class.name}: #{id} - #{updated_at}]"
    } or Time.zone.now.iso8601(4)
  end
end
