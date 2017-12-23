require_relative './core'

class Profistory
  class API < Core
    register Sinatra::Namespace
    register Kaminari::Helpers::SinatraHelpers
    disable :show_exceptions

    respond_to :json

    def api_key
      request.env["HTTP_X_PROFISTORY_API_KEY"]
    end

    def current_user
      @current_user ||= User.where(api_key: api_key).first
    end

    before do
      halt 401 if api_key.nil? || current_user.nil?
      request.body.rewind
      body = request.body.read
      if body != ""
        json_params = JSON.parse(body)
        json_params.each do |k, v|
          params[k] = v
        end
      end
    end

    namespace '/works' do
      get('.json')              { list_works  }
      get('/:title.json')       { show_work   }
      put('/:title.json')       { create_work }
      put('/:title/join.json')  { join_work   }
      put('/:title/leave.json') { leave_work  }
    end

    namespace '/users' do
      get('.json')            { list_users }
      get('/:user_name.json') { show_user  }
      put('/:user_name.json') { update_user }
    end

    namespace '/tags' do
      get('.json')       { list_tags }
      get('/:name.json') { show_tag  }
    end

    error Mongoid::Errors::DocumentNotFound do
      status 404
      {error: {message: "Not found"}}.to_json
    end

    error 401 do
      {error: {message: 'Unauthorized'}}.to_json
    end

    error 500 do |error|
      {error: {message: 'Internal server error'}}.to_json
    end
  end
end
