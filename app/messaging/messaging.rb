class Messaging
  class << self

    def publish(name, message, routing_key = name)
      @conn || init
      memoized_create_exchange(name).publish(message.to_json, routing_key: routing_key)
    end

    private

    def init
      begin

        @memoized_created_exchanges = {}

        Rails.logger.info 'Initializing messaging...'
        @conn = Bunny.new Settings[:messaging][:connection]
        @conn.start
        @ch = @conn.create_channel

      rescue Exception => e

        Rails.logger.warn Formatter.exception_to_log_s e
        puts 'Messaging is not available in this process!'

        unless %w(development test).include? Rails.env
          raise e
        end

      end
    end

    def create_exchange(name, options = {})
      @ch.exchange name, { type: 'topic', durable: true }.merge(options)
    end

    def memoized_create_exchange(name, options = {})
      ekey = name + '_' + @conn.hash.to_s
      @memoized_created_exchanges[ekey] ||
        @memoized_created_exchanges[ekey] = create_exchange(name, options)
    end

  end
end
