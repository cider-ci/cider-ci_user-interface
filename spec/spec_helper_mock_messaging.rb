require 'messaging'

if Rails.env.test?
  class Messaging
    class << self
      attr_accessor :published_messages
      def publish(*args)
        (@published_messages ||= []) << args
      end
    end
  end
end
