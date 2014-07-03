class Consumers::TrialEventUpdate

  def self.initialize ch
    Rails.logger.info "Initializing trial_event consumer ..."
    @queue= ch.queue("trial_event.update", durable: true)
    @trial_event_exchange = ch.topic("trial_event_topic",durable: true)
    @queue.bind(@trial_event_exchange, routing_key: 'update')

    @queue.subscribe(:exclusive => true, :ack => false) do |delivery_info, properties, payload|
      on_message delivery_info,properties,payload
    end
    Rails.logger.info "... initialized trial_event consumer."
  end

  def self.on_message delivery_info, properties, payload
    Rails.logger.debug [self, "on_message trial_event_topic update ", payload]

    begin 

      trial_attributes= JSON.parse(payload).deep_symbolize_keys

      Trial.find_by(id: trial_attributes[:id]).task.instance_eval do
        check_and_retry!
        update_state!
      end

    rescue Exception => e
      Rails.logger.error Formatter.exception_to_log_s(e)
      Rails.logger.error ["Failed to process trial state change payload:", payload]
    end

  end
end
