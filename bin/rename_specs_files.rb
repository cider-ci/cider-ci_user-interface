#!/usr/bin/env ruby
require 'pry'

Dir.glob('**/*task_spec*').each do |old_file|
  new_file = old_file.gsub /task_spec/, 'task_specification'
  puts "OLD: #{old_file}"
  puts "NEW: #{new_file}"
  File.rename old_file, new_file
end
