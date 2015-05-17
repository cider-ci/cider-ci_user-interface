
User.find_or_initialize_by(login: 'admin')  \
  .update_attributes! is_admin: true, password: 'secret'


Repository.find_or_initialize_by(name: 'Demo Project') \
  .update_attributes!(
    origin_uri: 'http://localhost:8888/cider-ci/demo-project-bash/',
    git_fetch_and_update_interval: 5, 
    public_view_permission: true)


Executor.find_or_initialize_by(name: "DemoExecutor") \
  .update_attributes!(base_url: "http://localhost:8883")

