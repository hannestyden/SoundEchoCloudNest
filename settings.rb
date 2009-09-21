def load_settings(setting)
  settings = {
    # Settings for SoundCloud
    :site                => "http://api.sandbox-soundcloud.com",
    :consumer_key        => nil, # *** YOUR CONSUMER KEY        *** #
    :consumer_secret     => nil, # *** YOUR CONSUMER SECRET     *** #
    :token_callback      => 'oob',
    :authorize_callback  => '',
    
    # This is optional:
    #   Run the script once to get an access token
    :access_token_key    => nil, # *** YOUR ACCESS TOKEN KEY    *** #
    :access_token_secret => nil, # *** YOUR ACCESS TOKEN SECRET *** #
    
    # Settings for EchoNest
    :echonest_key        => nil, # *** YOUR API KEY             *** #
  }
  
  if settings[:consumer_key].blank? || settings[:consumer_secret].blank?
    raise "Please register an application for #{settings[:site]} and configure #{__FILE__}."
  end
  
  if settings[:echonest_key].blank?
    raise "Please register an api key for EchoNest and configure #{__FILE__}."
  end
  
  settings
end
