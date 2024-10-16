require "spec_helper"

describe JobSpecification do
  context "example job_specification" do
    before :each do
      @ex_spec = JobSpecification.create! data: { x: 42 }
    end

    it "has a fixed id" do
      expect(@ex_spec.id).to be == "cb993bdb-3a90-5842-8e12-4236ba30e276"
    end

    describe "find_or_create_by_data" do
      it "returns the same existing instance " do
        expect(
          JobSpecification.find_or_create_by_data!(x: 42)
        ).to be == @ex_spec
      end
    end

    describe "updating the data" do
      it "raises an error" do
        expect do
          @ex_spec.update! data: { x: 7 }
        end.to raise_error(/Data is immutable/)
      end
    end
  end
end
