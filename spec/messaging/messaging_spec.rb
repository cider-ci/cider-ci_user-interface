require "spec_helper"

describe Messaging do 

  
  it "publishing a message doesn't raise an exception" do 
    expect{
      Messaging.publish "test.messages", {x: 7}
    }.not_to raise_exception
  end

end



