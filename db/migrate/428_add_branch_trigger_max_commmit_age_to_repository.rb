class AddBranchTriggerMaxCommmitAgeToRepository < ActiveRecord::Migration
  def change
    add_column :repositories, :branch_trigger_max_commit_age, :text, default: '12 hours'

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          ALTER TABLE repositories
            ADD CONSTRAINT branch_trigger_max_commit_age_not_blank
                CHECK (branch_trigger_max_commit_age !~ '^\\s*$');
        SQL
      end
    end
  end
end
