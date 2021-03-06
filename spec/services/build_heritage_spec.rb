require 'rails_helper'

describe BuildHeritage do
  before do
    allow_any_instance_of(Aws::ECS::Client).to receive(:create_cluster)
  end
  let(:params) do
    {
      name: "heritage",
      image_name: "docker_image",
      image_tag: "latest",
      env_vars: {
        "RAILS_ENV" => "production"
      },
      services: [
        {
          name: "web",
          cpu: 128,
          memory: 128,
          command: "rails s",
          public: true,
          port_mappings: [
            {
              lb_port: 80,
              container_port: 3000
            }
          ]
        },
        {
          name: "worker",
          command: "rake jobs:work"
        }
      ]
    }
  end
  let(:district) { create :district }
  let(:heritage) { BuildHeritage.new(params, district: district).execute }

  describe "new object" do
    subject { heritage }
    its(:district) { is_expected.to eq district }
    its(:name) { is_expected.to eq 'heritage' }
    its(:image_name) { is_expected.to eq 'docker_image' }
    its(:image_tag) { is_expected.to eq 'latest' }
  end

  describe "create object" do
    before do
      heritage.save!
    end

    it "has 2 services" do
      expect(heritage.services.count).to eq 2

      service1 = heritage.services.first
      expect(service1.id).to be_present
      expect(service1.name).to eq "web"
      expect(service1.cpu).to eq 128
      expect(service1.memory).to eq 128
      expect(service1.command).to eq "rails s"
      expect(service1.public).to eq true
      expect(service1.port_mappings.count).to eq 1
      expect(service1.port_mappings.first.lb_port).to eq 80
      expect(service1.port_mappings.first.container_port).to eq 3000

      service2 = heritage.services.second
      expect(service2.name).to eq "worker"
      expect(service2.cpu).to eq 512
      expect(service2.memory).to eq 512
      expect(service2.command).to eq "rake jobs:work"
      expect(service2.port_mappings.count).to eq 0
    end

    it "has env vars" do
      expect(heritage.env_vars[0].key).to eq "RAILS_ENV"
      expect(heritage.env_vars[0].value).to eq "production"
    end
  end

  describe "update object" do
    before do
      heritage.save!
    end

    context "with name" do
      before do
        new_params = params.dup
        new_params[:image_tag] = "branch"
        new_params[:services][0][:command] = "rails s -b 0.0.0.0"
        new_params[:services][1][:command] = "rake jobs:offwork"
        @updated_heritage = BuildHeritage.new(new_params, district: nil).execute
        @updated_heritage.save!
      end

      it "updates the heritage and associated records" do
        expect(@updated_heritage.services.count).to eq 2
        expect(@updated_heritage.image_tag).to eq "branch"

        service1 = @updated_heritage.services.first
        expect(service1.id).to be_present
        expect(service1.name).to eq "web"
        expect(service1.cpu).to eq 128
        expect(service1.memory).to eq 128
        expect(service1.command).to eq "rails s -b 0.0.0.0"
        expect(service1.public).to eq true
        expect(service1.port_mappings.count).to eq 1
        expect(service1.port_mappings.first.lb_port).to eq 80
        expect(service1.port_mappings.first.container_port).to eq 3000

        service2 = @updated_heritage.services.second
        expect(service2.name).to eq "worker"
        expect(service2.cpu).to eq 512
        expect(service2.memory).to eq 512
        expect(service2.command).to eq "rake jobs:offwork"
        expect(service2.port_mappings.count).to eq 0
      end

      it "has env vars" do
        expect(heritage.env_vars[0].key).to eq "RAILS_ENV"
        expect(heritage.env_vars[0].value).to eq "production"
      end
    end

    context "without name but id" do
      before do
        new_params = params.dup
        new_params[:id] = new_params.delete(:name)
        new_params[:image_tag] = "branch"
        new_params[:services][0][:command] = "rails s -b 0.0.0.0"
        new_params[:services][1][:command] = "rake jobs:offwork"
        @updated_heritage = BuildHeritage.new(new_params, district: nil).execute
        @updated_heritage.save!
      end

      it "updates the heritage and associated records" do
        expect(@updated_heritage.services.count).to eq 2
        expect(@updated_heritage.image_tag).to eq "branch"

        service1 = @updated_heritage.services.first
        expect(service1.id).to be_present
        expect(service1.name).to eq "web"
        expect(service1.cpu).to eq 128
        expect(service1.memory).to eq 128
        expect(service1.command).to eq "rails s -b 0.0.0.0"
        expect(service1.public).to eq true
        expect(service1.port_mappings.count).to eq 1
        expect(service1.port_mappings.first.lb_port).to eq 80
        expect(service1.port_mappings.first.container_port).to eq 3000

        service2 = @updated_heritage.services.second
        expect(service2.name).to eq "worker"
        expect(service2.cpu).to eq 512
        expect(service2.memory).to eq 512
        expect(service2.command).to eq "rake jobs:offwork"
        expect(service2.port_mappings.count).to eq 0
      end

      it "has env vars" do
        expect(heritage.env_vars[0].key).to eq "RAILS_ENV"
        expect(heritage.env_vars[0].value).to eq "production"
      end
    end
  end
end
