CiderCI::Application.routes.draw do

  get '/workspace', controller: 'workspace', action: 'index', as: 'workspace'

  match '/workspace/filter', via: [:get, :post],
                             controller: 'workspace', action: 'filter', as: 'workspace_filter'

  get :status, controller: :application, action: :status

  namespace 'workspace' do

    get 'show_raw/:table_name', action: :show_raw, as: :show_raw

    get :user

    namespace 'api' do
      get :index
    end

    resource :account, only: [:edit, :update] do
      post :email_addresses, to: 'accounts#add_email_address'
      delete '/email_address/:email_address',
        email_address: /[^\/]+/, to: 'accounts#delete_email_address',
        as: 'delete_email_address'
      post '/email_address/:email_address/as_primary',
        email_address: /[^\/]+/, to: 'accounts#as_primary_email_address',
        as: 'primary_email_address'
    end

    # TODO: doesn't work if the tag contains dots o_O
    resources :tags, only: [:index, :show]

    get 'branch_heads' # , controller: "workspace"

    resources :branches do
      collection do
        get 'names'
      end
    end

    # resources :branch_heads, only: [:index]

    resources :trials do
      member do
        post 'set_failed'
        get 'debug'
        get 'attachments'
        get 'result'
        get :issues, action: 'issues'
        delete 'issues/:issue_id', action: 'delete_issue', as: 'issue'
        get 'scripts-gantt-chart'
        get 'scripts-start-dependency-graph'
        get 'scripts-terminate-dependency-graph'
        get 'scripts/:key', action: :script, as: :script
      end
    end

    resources :branch_update_triggers
    resources :commits, only: [:show]
    resources :jobs, only: [:show, :create, :edit, :update] do
      member do
        get :tasks
        get :tree_attachments
        get :job_specification
        get :issues, action: 'issues'
        delete 'issues/:issue_id', action: 'delete_issue', as: 'issue'
        post :add_tags
        post :retry_and_resume
        post :abort
        get :result
        get :analytics
        get :statistics
      end
    end

    resources :trees, only: [:show] do
      get :attachments
      # TODO: rename to project_configuration
      get 'project-configuration'
      get 'project-configuration/validation', action: 'project_configuration_validation'
      resources :jobs, only: [:new]
    end

    resources :executors

    resources :repositories do
      resources :branches
      member do
        get 'git', as: 'git_root'
        get 'git/*path', action: 'get_git_file', format: false
      end
      collection do
        get 'names'
      end
    end

    resources :tasks do
      member do
        post 'retry'
        get 'result'
      end
    end

    get '/attachments/:kind/:path_id/*path', controller: :attachments,
                                             action: :show, constraints: { path: /.*/ },
                                             as: :attachment

  end

  namespace 'admin' do

    get :index

    resource :welcome_page_settings

    resource :status

    resources :branch_update_triggers
    resources :users do
      member do
        # resources :email_addreses
        get '/email_addresses', action: 'email_addressses'
        post '/email_addresses', action: 'add_email_address'
        put '/email_address/:email_address',
          email_address: /[^\/]+/, action: :put_email_address,
          as: :email_address
        post '/email_address/:email_address/as_primary',
          email_address: /[^\/]+/, action: :as_primary_email_address,
          as: :primary_email_address
        delete '/email_address/:email_address',
          email_address: /[^\/]+/, action: :delete_email_address,
          as: :delete_email_address
      end
    end
    resources :executors do
      member do
        post 'ping'
      end
    end
    resources :repositories do
      post 're_initialize_git'
      post 'update_git'
    end
    get 'env'
    post 'dispatch_trials'
  end

  resource :public, only: [:show], controller: 'public'

  namespace 'public' do
    post 'sign_in'
    post 'sign_out'

    get 'attachments/:repository_name/:branch_name/:job_name/*path',
      action: :redirect_to_tree_attachment_content,
      constraints: { path: /.*/ }

    get 'jobs/:repository_name/:branch_name/:job_name',
      action: :redirect_to_job

    get '/:repository_name/:branch_name/:job_names/summary',
      controller: 'summary', action: 'show', as: 'summary',
      constraints: { repository_name: /[^\/]+/, branch_name: /[^\/]+/,
                     job_names: /[^\/]+/ }

    resources :badges, only: [] do
      collection do
        get 'medium/:repository_name/:branch_name/:job_name', action: 'medium'
        get 'small/:repository_name/:branch_name/:job_name', action: 'small'
        # get ":repository/:branch_name/:job_name"
      end
    end
  end

  namespace 'perf' do
    root controller: 'perf', action: 'root'
  end

  get /.*/, controller: 'application', action: 'redirect'

  root 'application#redirect'

end
