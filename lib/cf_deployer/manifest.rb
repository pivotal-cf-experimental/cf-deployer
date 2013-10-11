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

    def admin_credentials
      users = find_in_manifest("properties", "uaa", "scim", "users")
      return unless users

      users.each do |user|
        username, password, _ = user.split("|")
        return username, password if username == "admin"
      end

      nil
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
