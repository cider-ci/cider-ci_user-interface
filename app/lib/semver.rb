module Semver
  def self.get
    Settings[:releases][0]
  end
end
