require 'rack-mini-profiler'
# Rack::MiniProfilerRails.initialize!(Rails.application)

# enable mini profiler on demand and not by default
c = Rack::MiniProfiler.config
c.authorization_mode = :whitelist
