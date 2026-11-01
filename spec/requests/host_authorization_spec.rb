# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Host authorization" do
  let(:allowed_hosts) do
    Rails.application.config_for(:allowed_hosts, env: "production")
  end
  let(:app) do
    ActionDispatch::HostAuthorization.new(
      Rails.application,
      allowed_hosts,
      exclude: B3s::Application::HEALTH_CHECK_REQUEST
    )
  end

  def get_with_host(path, host)
    Rack::MockRequest.new(app).get(path, "HTTP_HOST" => host)
  end

  it "allows the proxy hosts" do
    expect(allowed_hosts).to match_array(
      YAML.load_file(Rails.root.join("config/deploy.yml")).dig("proxy", "hosts")
    )
  end

  %w[b3s.me www.b3s.me butt3rscotch.org www.butt3rscotch.org
     b3s.vimes.elektronaut.no].each do |host|
    it "lets requests for #{host} through" do
      expect(get_with_host("/", host).status).not_to eq(403)
    end
  end

  it "blocks requests for other hosts" do
    expect(get_with_host("/", "evil.example.com").status).to eq(403)
  end

  it "blocks requests with a disallowed forwarded host" do
    response = Rack::MockRequest.new(app).get(
      "/", "HTTP_HOST" => "b3s.me", "HTTP_X_FORWARDED_HOST" => "evil.example.com"
    )
    expect(response.status).to eq(403)
  end

  it "lets health checks through for any host" do
    expect(get_with_host("/up", "10.0.0.5:8080").status).to eq(200)
  end
end
