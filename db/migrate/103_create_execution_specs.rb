class CreateExecutionSpecs < ActiveRecord::Migration

  def change


   reversible do |dir|
      dir.up do 
        execute "DROP TABLE IF EXISTS definitions CASCADE"
        execute "DROP TABLE IF EXISTS specifications CASCADE"
      end
    end

    create_table :specifications, id: false do |t|
      t.uuid :id 
      t.json :data
    end

    rename_column :executions, :definition_name, :name
    
    remove_column :executions, :specification_id, :string, index: true
    add_column :executions, :specification_id, :uuid, index: true
    add_index :executions, [:tree_id, :specification_id]


    remove_column :executions, :substituted_specification_data, :text
    add_column :executions, :expanded_specification_id, :uuid, index: true


    reversible do |dir|
      dir.up do 
        execute "ALTER TABLE specifications ADD PRIMARY KEY (id)"
        add_foreign_key :executions, :specifications
        add_foreign_key :executions, :specifications, column: :expanded_specification_id
      end
    end

    create_table :definitions, id: false do |t|
      t.string :name, null: false
      t.string :description
      t.uuid :specification_id
    end

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE definitions ADD PRIMARY KEY (name)"
      end
    end

  end
end
