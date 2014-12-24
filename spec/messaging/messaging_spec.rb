require 'spec_helper'

describe Messaging do

  it "publishing a message doesn't raise an exception" do
    pending("disabled for now since we don't have rabbitmq on the ci executors yet")
    # expect{ Messaging.publish "test.messages", {x: 7} }.not_to raise_exception
    fail
  end

end
