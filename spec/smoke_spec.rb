require "rails_helper"

RSpec.describe "Smoke", type: :request do
  it "health endpoint responds" do
    get "/up", headers: { "HOST" => "localhost" }
    expect(response).to have_http_status(:ok)
  end
end
