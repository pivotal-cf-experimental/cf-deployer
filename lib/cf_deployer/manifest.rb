require 'yaml'

module CfDeployer
  class ReleaseManifest

    class << self
      def load_file(filename)
        ReleaseManifest.new(YAML.load_file(filename))
      end
    end

    def initialize(content_hash)
      @content = content_hash
    end

    def api_endpoint
      find_in_manifest("properties", "cc", "srv_api_uri")
    end

    def services_credentials
      creds = find_in_manifest("properties", "uaa_client_auth_credentials")
      creds ? [creds['username'], creds['password']] : nil
    end

    def service_tokens
      appdirect_tokens + mysql_token
    end

    private

    attr_reader :content

    def appdirect_tokens
      find_in_manifest("properties", "appdirect_gateway", "services") || []
    end

    def mysql_token
      token = content['jobs'].find {|job| job['name'] == 'mysql_gateway'}['properties']['mysql_gateway']['token'] rescue nil

      if token
        [{
          'name'     => 'mysql',
          'provider' => 'core',
          'auth_token' => token
        }]
      else
        []
      end
    end

    def find_in_manifest(*path)
      path.inject(content) do |here, (key, _)|
        return nil unless here.is_a?(Hash) && here.has_key?(key)
        here[key]
      end
    end
  end
end
