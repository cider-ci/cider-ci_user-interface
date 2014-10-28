require 'spec_helper'

describe Specification do

  it "is creatable" do
    expect{FactoryGirl.create :specification}.not_to raise_error
  end


  describe "data created by the factory" do

    before :each do
      @specification = FactoryGirl.create :specification
    end

  end

  describe "immutability of the data" do

    before :each do
      @specification = FactoryGirl.create :specification
    end

    it "is protected on update" do
      expect{@specification.update_attributes! data: {tasks:[{command: "ls"}]}}.to raise_error
    end

  end

  describe "id_hash" do
    it "maps to a constant uuid" do 
      expect(Specification.id_hash(x: 42)).to be== "cb993bdb-3a90-5842-8e12-4236ba30e276" 
    end
  end

  describe "find_or_create_by_data!" do
    
    it "doesn't raise" do
      expect{Specification.find_or_create_by_data!(x: 42)}.not_to raise_error
    end

    describe "a Specification created by find_or_create_by_data!" do

      before :each do
          @spec= Specification.find_or_create_by_data!(x: 42)
      end

      it "has the id computed by the id_hash fun" do
        expect(@spec.id).to be== "cb993bdb-3a90-5842-8e12-4236ba30e276" 
      end

      it "has the proper data value" do
        expect(@spec.data).to be== {"x" => 42}
      end


    end

  end

end
