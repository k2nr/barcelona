module Backend::Ecs
  class Service
    attr_accessor :service
    delegate :service_name, :cpu, :memory, :command, :port_mappings, :district, to: :service
    delegate :aws, to: :district

    def initialize(service)
      @service = service
    end

    def scale(desired_count)
      aws.ecs.update_service(cluster: district.name,
                         service: service_name,
                         desired_count: desired_count)
    end

    def delete
      return unless applied?
      scale(0)
      aws.ecs.delete_service(cluster: district.name, service: service.service_name)
    end

    def status
      return :not_created if ecs_service.nil?
      deployment_statuses = ecs_service.deployments.map(&:status)
      if ecs_service.status != "ACTIVE"
        :inactive
      elsif deployment_statuses.include? "ACTIVE"
        :deploying
      elsif deployment_statuses == ["PRIMARY"]
        :active
      else
        :unknown
      end
    end

    def container_definition
      {
        name: service_name,
        cpu: cpu,
        memory: memory,
        essential: true,
        image: service.heritage.image_path,
        command: command.try(:split, " "),
        port_mappings: port_mappings.map{ |m|
          {
            container_port: m.container_port,
            host_port: m.host_port
          }
        },
        environment: service.heritage.env_vars.map { |e| {name: e.key, value: e.value} },
        log_configuration: {
          log_driver: "syslog",
          options: {
            "syslog-address" => "tcp://127.0.0.1:514",
            "syslog-tag" => service_name
          }
        }
      }.compact
    end

    def applied?
      !(ecs_service.nil? || ecs_service.status != "ACTIVE")
    end

    def register_task
      aws.ecs.register_task_definition(family: service.service_name,
                                   container_definitions: [container_definition])
    end

    def update
      aws.ecs.update_service(
        cluster: district.name,
        service: service.service_name,
        task_definition: service.service_name
      )
    end

    def create(load_balancer)
      params = {
        cluster: district.name,
        service_name: service.service_name,
        task_definition: service.service_name,
        desired_count: 1
      }
      if load_balancer.present?
        params[:load_balancers] = port_mappings.map do |port_mapping|
          {
            load_balancer_name: load_balancer.load_balancer_name,
            container_name: service_name,
            container_port: port_mapping.container_port
          }
        end
        params[:role] = district.ecs_service_role
      end
      aws.ecs.create_service(params)
    end

    def ecs_service
      @ecs_service ||= fetch_ecs_service
    end

    def fetch_ecs_service
      @ecs_service = aws.ecs.describe_services(
        cluster: district.name,
        services: [service.service_name]
      ).services.first
    end
  end
end
