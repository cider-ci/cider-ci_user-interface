class V4Start < ActiveRecord::Migration
  def change
    execute (IO.read (Rails.root.join "db", "migrate", "400.sql"))
  end
end
