class ActiveRecord::Base
  def self.collection_cache_tag &block
    if block_given?
      block.call(self)
    else
      self
    end.instance_eval {
      t= reorder(updated_at: :desc).limit(1) \
        .select("to_char(#{table_name}.updated_at,'YYYY-MM-DDThh:mm:ss.msTZ') as t").first.try(:[],:t)
      c= count
     "[#{table_name}: #{c} - #{t}]"
    } or Time.zone.now.iso8601(4)
  end
end
