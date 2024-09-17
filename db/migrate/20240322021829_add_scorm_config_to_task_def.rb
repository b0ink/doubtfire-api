class AddScormConfigToTaskDef < ActiveRecord::Migration[7.0]
  def change
    change_table :task_definitions do |t|
      t.boolean :scorm_enabled, default: false
      t.boolean :scorm_allow_review, default: false
      t.boolean :scorm_bypass_test, default: false
      t.boolean :scorm_time_delay_enabled, default: false
      t.integer :scorm_attempt_limit, default: 0
    end
  end

  def down
    change_table :task_definitions do |t|
      t.remove :scorm_enabled
      t.remove :scorm_allow_review
      t.remove :scorm_bypass_test
      t.remove :scorm_time_delay_enabled
      t.remove :scorm_attempt_limit
    end
  end
end
