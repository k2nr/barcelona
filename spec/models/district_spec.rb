require 'rails_helper'

describe District, :vcr do
  let(:district) { create(:district) }

  describe "#subnets" do
    before do
      Aws.config[:stub_responses] = false
    end

    it "returns private subnets" do
      expect(district.subnets("Private").count).to eq 2
    end
    it "returns public subnets" do
      expect(district.subnets("Public").count).to eq 2
    end
  end

  describe "#container_instances" do
    before do
      Aws.config[:stub_responses] = false
    end

    it "returns container instances and ec2 instances information" do
      result = district.container_instances
      expect(result).to be_a Array
      expect(result.count).to eq 1
      expect(result.first).to have_key :container_instance_arn
      expect(result.first).to have_key :ec2_instance_id
      expect(result.first).to have_key :private_ip_address
    end
  end

  describe "#launch_instances" do
    before do
      Aws.config[:stub_responses] = false
    end

    subject { district.launch_instances(count: 1, instance_type: 't2.micro') }

    it "launches EC2 instance" do
      is_expected.to_not be_nil
    end
  end
end
