class Consumers::BranchEvent

  def self.initialize ch
    Rails.logger.info "Initializing branch_event consumer ..."
    @queue= ch.queue("branch_event", durable: true)
    @branch_event_exchange = ch.topic("branch_event_topic",durable: true)
    @queue.bind(@branch_event_exchange, routing_key: '#')

    @queue.subscribe(:exclusive => true, :ack => false) do |delivery_info, properties, payload|
      on_message delivery_info,properties,payload
    end
    Rails.logger.info "... initialized branch_event consumer."
  end

  def self.on_message delivery_info, properties, payload
    Rails.logger.info [self, "on_message", delivery_info, properties, payload]
    case delivery_info[:routing_key]
    when "branch_event.update"
      message= JSON.parse payload
      Rails.logger.debug ["branch_event.update message", message]
      process_branch_update message
    else
      Rails.logger.warn ["Untreated event", delivery_info,properties,payload]
    end
  end

  def self.process_branch_update message
    branch = message.deep_symbolize_keys

    BranchUpdateTrigger.active \
      .where(branch_id: branch[:id]).each do |branch_update_trigger| 

      Rails.logger.info "Creating new execution on behalf of branch update" 

      ExceptionHelper.with_log_and_reraise do

        @commit = Commit.find(branch[:current_commit_id])

        @execution = Execution.create! \
          specification: branch_update_trigger.definition.specification, 
          definition_name: branch_update_trigger.definition.name,
          tree_id: @commit.tree_id

        @execution.tags= branch_update_trigger.tags

        @execution.add_strings_as_tags [branch.name,branch.repository.name]

      end

      @execution.create_tasks_and_trials
    end
  end

end

