def create_and_or_update(entity, primary_attribute_name,
  primary_attribute, config)

  primary_map = { primary_attribute_name => primary_attribute }

  instance = entity.find_by(primary_map)

  create_attributes = config['create-attributes'].presence || {}

  instance ||= entity.create! primary_map.merge(create_attributes.to_h)

  update_attributes = config['update-attributes'].presence

  if (instance && update_attributes)
    instance.update_attributes! update_attributes.to_h
  end
end

Settings.managed_users.try(:each) do |login, config|
  create_and_or_update User, 'login', login, config
end

Settings.managed_repositories.try(:each) do |git_url, config|
  create_and_or_update Repository, 'git_url', git_url, config
end
