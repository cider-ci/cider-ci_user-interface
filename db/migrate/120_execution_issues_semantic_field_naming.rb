class ExecutionIssuesSemanticFieldNaming < ActiveRecord::Migration
  def change
    rename_column :execution_issues, :description, :title
    rename_column :execution_issues, :stacktrace, :description
  end
end
