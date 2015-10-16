class ExceptionHandler
  class Exception < StandardError
    attr_accessor :errors

    def initialize(errors = [])
      super
      @errors = errors
    end

    def to_rack_response(debug=false)
      [status_code, headers, [body(debug)]]
    end

    def status_code
      500
    end

    def headers
      { "Content-Type" => "application/json" }
    end

    def body(debug)
      data = { errors: errors.presence || [default_error] }
      if debug
        data.merge!(
          backtrace: original.backtrace,
          debug_message: original.message
        )
      end
      data.to_json
    end

    private

    def original
      cause || self
    end

    def error_type
      self.class.to_s.split("::").last.underscore
    end

    def default_error
      {
        type: error_type
      }
    end
  end

  class InternalServerError < Exception
  end

  class Unauthorized < Exception
    def status_code
      401
    end
  end

  class UnprocessableEntity < Exception
    def status_code
      422
    end
  end

  class NotFound < Exception
    def status_code
      404
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ExceptionHandler::Exception => e
      raise e
    rescue ActiveRecord::RecordNotFound
      raise NotFound
    rescue ActiveRecord::RecordInvalid => e
      raise UnprocessableEntity.new(e.message)
    rescue
      raise InternalServerError
    end
  rescue ExceptionHandler::Exception => e
    debug = Rails.env.development? || query_parameters(env)["debug"] == "true"
    e.to_rack_response(debug)
  end

  def query_parameters(env)
    Hash[env["QUERY_STRING"].split('&').map{ |s| s.split("=") }]
  end
end
