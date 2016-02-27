module Concerns::AuthProvider::GitHub
  extend ActiveSupport::Concern

  def github_get_token(config)
    uri = Addressable::URI.parse("#{config.oauth_base_url}/access_token")
    uri.query_values = { client_id: config.client_id, client_secret: config.client_secret,
                         code: params[:code], state: params[:state] }
    JSON.parse(Faraday.new(uri.to_s) do |f|
      f.use Faraday::Response::RaiseError
      f.request :retry
      f.adapter Faraday.default_adapter
    end.post do |req|
      req.headers['Accept'] = 'application/json'
    end.body)['access_token']
  end

  def github_get_email_addresses(config, token)
    url = "#{config.api_endpoint}/user/emails?access_token=#{token}"
    JSON.parse(Faraday.new(url) do |f|
      f.use Faraday::Response::RaiseError
      f.request :retry
      f.adapter Faraday.default_adapter
    end.get.body).map(&:with_indifferent_access) \
      .select { |x| x[:verified] }.map { |x| x[:email] }
  end

  def github_get_user(config, token)
    url = "#{config.api_endpoint}/user?access_token=#{token}"
    JSON.parse(Faraday.new(url) do |f|
      f.use Faraday::Response::RaiseError
      f.request :retry
      f.adapter Faraday.default_adapter
    end.get.body).with_indifferent_access
  end

  def github_sign_in
    config = get_provider_config(:github)
    state = CiderCi::OpenSession::Encryptor.decrypt(
      Rails.application.secrets.secret_key_base,
      params[:state]).with_indifferent_access

    github_user_access_token = github_get_token(config)

    github_user_properties = github_get_user config, github_user_access_token

    github_email_addresses = github_get_email_addresses config, github_user_access_token

    if strategy = config['sign-in_strategies'].detect do |strategy|
        case strategy['type']
        when 'email-addresses'
          (strategy['email-addresses'].map(&:downcase) &
           github_email_addresses.map(&:downcase)).any?
        when 'organization-membership'
          github_satisfies_organization_membership_strategy? config, strategy,
            github_user_properties, github_user_access_token
        when 'team-membership'
          github_satisfies_team_membership_strategy? config, strategy,
            github_user_access_token, github_user_properties
        end
       end

        user = github_create_and_update_user config, strategy,
          github_user_properties, github_user_access_token, github_email_addresses

        create_services_session_cookie user
        redirect_to state[:full_path]
    else
      raise CiderCI::NotAuthorized, <<-ERR.strip_heredoc
        None of the accepted sign-in criterias matches with your account.
        Contact your system administrator.
      ERR
    end
  end

  def github_satisfies_organization_membership_strategy?(config, strategy,
    github_user_properties, github_user_access_token)
    url = "#{config.api_endpoint}/orgs/" \
      << strategy['organization-login'] \
      << '/members/' << github_user_properties['login'] \
      << "?access_token=#{strategy.access_token.presence || github_user_access_token}"
    [204, 302].include?(
      Faraday.new(url) do |f|
        f.request :retry
        f.adapter Faraday.default_adapter
      end.get.status)
  end

  def github_satisfies_team_membership_strategy?(config, strategy,
    github_user_access_token, github_user_properties)
    team_id_query_url = "#{config.api_endpoint}/orgs/" \
      << strategy['organization-login'] << '/teams' \
      << '?per_page=100&access_token=' \
      << (strategy.access_token.presence || github_user_access_token)
    # TODO: handle pagination properly; (are there orgs with +100 teams?)
    team_id_response = Faraday.new(team_id_query_url) do |f|
      f.request :retry
      f.adapter Faraday.default_adapter
    end.get
    if team_id_response.status.between?(200, 299)
      if team_id = JSON.parse(team_id_response.body) \
          .detect { |t| t['name'] == strategy['team-name'] } \
          .try(:[], 'id')
        membership_query =  "#{config.api_endpoint}/teams/" \
          << team_id.to_s << '/memberships/' << github_user_properties['login'] \
          << "?access_token=#{strategy.access_token.presence || github_user_access_token}"
        membership_response = Faraday.new(membership_query) do |f|
          f.request :retry
          f.adapter Faraday.default_adapter
        end.get
        membership_response.status.between?(200, 299)
      end
    end
  end

  def github_request_authentication
    config = get_provider_config(:github)
    uri = Addressable::URI.parse("#{config.oauth_base_url}/authorize")
    secret = Rails.application.secrets.secret_key_base
    state = CiderCi::OpenSession::Encryptor.encrypt(secret,
      full_path: params[:current_fullpath])
    uri.query_values = { client_id: config.client_id,
                         scope: 'user:email,read_org',
                         state: state }
    redirect_to uri.to_s
  end

  def github_create_and_update_user(config, strategy,
    github_user_properties, github_user_access_token, github_email_addresses)

    github_id = github_user_properties['id']
    user = User.find_by(github_id: github_id) || \
      User.create!((strategy['create-attributes'] || {}) \
                   .to_h.merge(github_id: github_id,
                               login: login(github_user_properties, config)))
    user.update_attributes! (strategy['update-attributes'] || {}).to_h.merge(
      name: github_user_properties['name'],
      login: login(github_user_properties, config),
      github_access_token: github_user_access_token)
    create_or_associate_email_addresses_with_user(user,
      github_email_addresses)
    user
  end

end
