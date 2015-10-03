class District < ActiveRecord::Base
  extend Memoist

  attr_accessor :dockercfg

  before_save :update_ecs_config
  before_create :create_ecs_cluster
  after_destroy :delete_ecs_cluster

  has_many :heritages, dependent: :destroy

  validates :name, presence: true
  validates :vpc_id, presence: true
  validates :private_hosted_zone_id, presence: true

  def to_param
    name
  end

  def subnets(network)
    Aws::EC2::Client.new.describe_subnets(
      filters: [
        {name: "vpc-id", values: [vpc_id]},
        {name: 'tag:Network', values: [network]}
      ]
    ).subnets
  end

  def launch_instances(count: 1)
    ec2.run_instances(
      image_id: 'ami-ce2ba4ce', # amzn-ami-2015.03.g-amazon-ecs-optimized
      min_count: count,
      max_count: count,
      key_name: 'kkajihiro',
      security_group_ids: [instance_security_group].compact,
      user_data: instance_user_data,
      instance_type: 't2.micro',
      subnet_id: subnets("Private").sample.subnet_id,
      iam_instance_profile: {
        name: ecs_instance_role
      }
    )
  end

  private

  def update_ecs_config
    return if dockercfg.blank?
    s3.put_object(bucket: s3_bucket_name,
                  key: "#{name}/ecs.config",
                  body: ecs_config,
                  server_side_encryption: "AES256")
  end

  def create_ecs_cluster
    ecs.create_cluster(cluster_name: name)
  end

  def instance_user_data
    user_data = [
      "#!/bin/bash",
      "yum install -y aws-cli",
      "aws s3 cp s3://#{s3_bucket_name}/#{name}/ecs.config /etc/ecs/ecs.config"
    ].join("\n")
    Base64.encode64(user_data)
  end

  def ecs_config
    {
      "ECS_CLUSTER" => name,
      "ECS_ENGINE_AUTH_TYPE" => "dockercfg",
      "ECS_ENGINE_AUTH_DATA" => dockercfg.to_json
    }.map {|k, v| "#{k}=#{v}"}.join("\n")
  end

  def delete_ecs_cluster
    ecs.delete_cluster(cluster: name)
  end

  def ecs
    Aws::ECS::Client.new
  end

  def s3
    Aws::S3::Client.new
  end

  def ec2
    Aws::EC2::Client.new
  end

  memoize :subnets, :ecs
end
