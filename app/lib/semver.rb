module Semver
  def self.get
    @release ||= Settings[:releases][0]
  end
end
