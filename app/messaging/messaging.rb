
class Messaging
  def self.initialize

    begin 

      Rails.logger.info "Initializing messaging..." 
      @conn = Bunny.new Settings.messaging.connection.to_hash
      @conn.start
      @ch = @conn.create_channel

      unless ENV['MESSAGING_BIND_CONSUMERS'].blank?

        Consumers::BranchEvent.initialize(@ch)

        Consumers::TrialEventUpdate.initialize(@ch)

        Rails.logger.info "... initialized messaging." 

      else

        Rails.logger.warn "messaging consumers are not bound!"
        puts "messaging consumers are not bound!"

      end

    rescue Bunny::TCPConnectionFailed => e

      Rails.logger.warn Formatter.exception_to_log_s e
      puts "Messaging is not available in this process!"

      unless %w(development test).include? Rails.env 
        raise e
      end

    end

  end
end
