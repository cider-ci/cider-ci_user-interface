module CacheSignature
  def self.signature(*args)
    Digest::MD5.hexdigest(args.map do |arg|
      if arg.respond_to? :to_a
        signature(*arg.to_a.flatten)
      elsif arg.is_a? ActiveRecord::Base
        signature(*arg.attributes.to_a.flatten)
      else
        arg.to_s
      end
    end.join)
  end
end
