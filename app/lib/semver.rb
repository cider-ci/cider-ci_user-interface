module Semver
  def self.get
    @release ||= get_and_set_build
  end

  def self.get_and_set_build
    release = Settings.releases[0]
    if release.version_pre
      release.version_build = `cd .. && git log -n 1 --format='%h'`.strip
    end
    release
  end
end
