class CascadeDeleteBranches < ActiveRecord::Migration
  def change
    remove_foreign_key :branches, :repositories
    add_foreign_key :branches, :repositories, on_delete: :cascade
  end
end
