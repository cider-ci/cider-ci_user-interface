CiderCI::Application.routes.draw do

  get '/workspace/dashboard', controller: 'workspace', action: 'dashboard'

  post '/configuration_management/invoke', controller: 'configuration_management', action: 'invoke'

  namespace 'workspace' do

    get :user

    namespace 'api' do
      get :index
    end

    resource :account, only: [:edit, :update] do
      post :email_addresses, to: 'accounts#add_email_address'
      delete '/email_address/:email_address', email_address: /[^\/]+/, to: 'accounts#delete_email_address', as: 'delete_email_address'
      post '/email_address/:email_address/as_primary', email_address: /[^\/]+/, to: 'accounts#as_primary_email_address', as: 'primary_email_address'
    end

    resource :session, only: [:edit, :update]

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
        get 'attachments'
        get 'result'
        get :issues, action: 'issues'
        delete 'issues/:issue_id', action: 'delete_issue', as: 'issue'
      end
    end

    resources :branch_update_triggers
    resources :commits
    resources :executions do
      member do
        get :tasks
        get :tree_attachments
        get :specification
        get :issues, action: 'issues'
        delete 'issues/:issue_id', action: 'delete_issue', as: 'issue'
        post :add_tags
        post :retry_failed
        get 'result'
      end
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

    get '/attachments/:kind/*path', controller: :attachments,
                                    action: :show, constraints: { path: /.*/ },
                                    as: :attachment

  end

  namespace 'admin' do

    get :index

    resource :timeout_settings
    resource :welcome_page_settings

    resource :status

    resources :branch_update_triggers
    resources :definitions
    resources :users do
      member do
        # resources :email_addreses
        get '/email_addresses', action: 'email_addressses'
        post '/email_addresses', action: 'add_email_address'
        put '/email_address/:email_address', email_address: /[^\/]+/, action: :put_email_address, as: :email_address
        post '/email_address/:email_address/as_primary', email_address: /[^\/]+/, action: :as_primary_email_address, as: :primary_email_address
        delete '/email_address/:email_address', email_address: /[^\/]+/, action: :delete_email_address, as: :delete_email_address
        # delete '/email_address/:email_address', email_address: /[^\/]+/, action: 'delete_email_address', as: :email_address
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

    # ħttp://localhost:8880/cider-ci/ui/public/attachments/Cider-CI%20Bash%20Demo%20Project/master/Tests/log/hello.txt
    #
    get 'attachments/:repository_name/:branch_name/:execution_name/*path',
        action: :redirect_to_tree_attachment_content,
        constraints: { path: /.*/ }

    get 'executions/:repository_name/:branch_name/:execution_name',
        action: :redirect_to_execution

    get '/:repository_name/:branch_name/:execution_names/summary',
        controller: 'summary', action: 'show', as: 'summary'

    resources :badges, only: [] do
      collection do
        get 'medium/:repository_name/:branch_name/:execution_name', action: 'medium'
        get 'small/:repository_name/:branch_name/:execution_name', action: 'small'
        # get ":repository/:branch_name/:execution_name"
      end
    end
  end

  namespace 'perf' do
    root controller: 'perf', action: 'root'
  end

  get /.*/, controller: 'application', action: 'redirect'

  root 'application#redirect'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
