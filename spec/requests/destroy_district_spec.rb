require 'rails_helper'

describe "DELETE /districts/:district", :vcr, type: :request do
  let(:auth) { {"X-Barcelona-Token" => user.token} }
  let(:district) { create :district }

  before do
    allow_any_instance_of(District).to receive(:subnets) {
      [double(subnet_id: 'subnet_id')]
    }
  end

  context "when a user is a developer" do
    let(:user) { create :user, roles: ["developer"] }
    it "returns 401" do
      delete "/districts/#{district.name}", nil, auth
      expect(response.status).to eq 401
    end
  end

  context "when a user is an admin" do
    let(:user) { create :user, roles: ["admin"] }
    it "destroys a district" do
      delete "/districts/#{district.name}", nil, auth
      expect(response.status).to eq 204
    end
  end
end
