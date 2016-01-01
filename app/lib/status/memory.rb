module Status::Memory
  extend ActionView::Helpers::NumberHelper
  class << self

    def status
      if RUBY_ENGINE == 'jruby'

      max_usage = Settings.status_limits.memory.max_usage rescue 0.95
      min_free = Settings.status_limits.memory.min_free rescue 10.megabytes

      java.lang.System.gc
      rt  = java.lang.Runtime.getRuntime
      max = rt.maxMemory
      allocated = rt.maxMemory
      free = rt.freeMemory
      used = (allocated - free)
      usage = (used / max.to_f)
      is_ok = usage < max_usage && free >= min_free

      OpenStruct.new is_ok: is_ok, content: {
        memory: { Max: number_to_human_size(max),
                  Allocated: number_to_human_size(allocated),
                  Used: number_to_human_size(used),
                  Usage: usage.round(2),
                  OK?: is_ok } }.with_indifferent_access.as_json
      else

        OpenStruct.new is_ok: true, content: {}

      end
    end
  end
end
