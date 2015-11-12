
User.find_or_initialize_by(login: 'admin')  \
  .update_attributes! is_admin: true, password: 'secret'

Repository.find_or_initialize_by(name: 'Cider-CI Bash Demo Project') \
  .update_attributes!(
    git_url: Rails.root.join("..","demo-project-bash").to_s,
    git_fetch_and_update_interval: 5,
    public_view_permission: true)


Executor.find_or_initialize_by(name: "DemoExecutor",
   id: "35cff40c-b4f8-4ca3-9217-d49c9c35f375") \
 .update_attributes!(base_url: 'http://localhost:8883')

