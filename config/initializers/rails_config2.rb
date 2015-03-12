Settings.add_source! Rails.root.join('..', 'config', 'config_default.yml').to_s
Settings.add_source! Rails.root.join('..', 'config', 'config.yml').to_s
Settings.add_source! Rails.root.join('..', 'config', 'releases.yml').to_s
Settings.reload!
