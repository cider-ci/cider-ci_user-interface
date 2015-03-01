if %w(development test).include? Rails.env
  Settings.add_source! Rails.root.join('..', 'config', 'config_default.yml').to_s
else
  Settings.add_source! '/etc/cider-ci/conf.yml'
end
Settings.reload!
