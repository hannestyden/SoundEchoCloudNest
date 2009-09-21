require 'settings'

module SC
  def self.connect
    setting = ((s = ENV['SETTING']) && s.to_sym) || :sandbox
    
    settings = load_settings(setting)
    consumer = Soundcloud.consumer(settings[:consumer_key], settings[:consumer_secret], settings[:site])
    
    begin
      unless settings[:access_token_key] && settings[:access_token_secret]
        request_token = consumer.get_request_token(:oauth_callback => settings[:token_callback])
        
        if (oauth10a = request_token.respond_to?(:callback_confirmed?) && request_token.callback_confirmed?)
          puts "OAuth 1.0a detected"
        end
        
        authorize_url = request_token.authorize_url(:oauth_callback => settings[:authorize_callback])
        puts "Opening: #{authorize_url}"
        puts `open '#{authorize_url}'`
        
        if oauth10a
          puts "What is the 'oauth_verifier'?"
          oauth_verifier = gets.chomp
          
          access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        else
          puts "Authorized?"
          gets
          
          access_token = request_token.get_access_token
        end
        
        puts "You can now add"
        puts "access_token_key    #{access_token.token}"
        puts "and"
        puts "access_token_secret #{access_token.secret}"
        puts "to your settings file (#{settings[:file]})."
      else
        access_token = OAuth::AccessToken.new(consumer, settings[:access_token_key], settings[:access_token_secret])
      end
      
      if access_token
        yield Soundcloud.register({:access_token => access_token, :site => settings[:site]}), settings
      else
        puts "No access token available."
      end
    rescue OAuth::Unauthorized
      puts "Unauthorized"
    end
  end
end
