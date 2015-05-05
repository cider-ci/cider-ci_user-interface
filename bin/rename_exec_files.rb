#!/usr/bin/env ruby
require 'pry'

Dir.glob('**/*execution*').each do |old_file|
  new_file = old_file.gsub /execution/, 'job'
  puts "OLD: #{old_file}"
  puts "NEW: #{new_file}"
  File.rename old_file, new_file
end
