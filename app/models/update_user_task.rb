class UpdateUserTask
  attr_accessor :district, :user

  def initialize(district, user)
    @district = district
    @user = user
  end

  def run
    Rails.logger.info "Updating user #{user.name} for district #{district.name}"
    ecs.register_task_definition(
      family: "update_user",
      container_definitions: [
        {
          name: "update_user",
          cpu: 32,
          memory: 32,
          essential: true,
          image: "k2nr/docker-user-manager",
          mount_points: [
            {
              source_volume: "etc",
              container_path: "/etc"
            },
            {
              source_volume: "home",
              container_path: "/home"
            }
          ]
        }
      ],
      volumes: [
        {
          name: "etc",
          host: {
            source_path: "/etc"
          }
        },
        {
          name: "home",
          host: {
            source_path: "/home"
          }
        }
      ]
    )

    resp = ecs.start_task(
      cluster: district.name,
      task_definition: "update_user",
      overrides: {
        container_overrides: [
          {
            name: "update_user",
            environment: [
              {
                name: "USER_NAME",
                value: user.name
              },
              {
                name: "USER_PUBLIC_KEY",
                value: user.public_key
              }
            ]
          }
        ]
      },
      container_instances: district.container_instances.map{ |c| c[:container_instance_arn] }
    )
  end

  private

  def ecs
    @ecs ||= Aws::ECS::Client.new
  end
end
