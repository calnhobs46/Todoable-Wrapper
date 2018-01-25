require 'todo_wrapper/version'
require 'net/http'
require 'uri'
require 'json'

class APIWrapper
  def self.authenticate(username, password)
    if username.length == 0
      raise ArgumentError, 'Please input a username string'
    elsif password.length == 0
      raise ArgumentError, 'Please input a password string'
    end

    if username.length > 0 and password.length > 0
      @@username = username
      @@password = password
    end
  end

  def username
    return @@username
  end

  def password
    return @@password
  end

  def token
    return @@token
  end

  def expires
    return @@expires
  end

  def start_session
    response = base_uri('post','authenticate', nil)
    parse_auth_response(response)
    return response
  end

  def parse_auth_response(response)
    json = JSON.parse(response.body)
    @@token = json['token']
    @@expires = json['expires_at']
  end

  def parse_422_response(response)
    json = JSON.parse(response.body)
    json.each do |key, value|
      raise Exception, "The input value: #{key} is invalid: #{value[0]}"
    end
  end

  def base_uri(method, url_add, data=nil)
    if self.username.length() == 0 or self.password.length() == 0
      raise StandardError, 'Need to add a username and password in order to run commands'
    else
      uri = URI.parse('http://todoable.teachable.tech/api/' + url_add)
      request = http_method(method).new(uri)
      if url_add === 'authenticate'
        request.basic_auth(self.username, self.password)
      else
        request['Authorization'] = 'Token token=' + self.token
      end

      unless data.nil?
        if url_add.include? 'items'
          request.body = JSON.dump({'item' => { 'name' => data }})
        else
          request.body = JSON.dump({'list' => { 'name' => data }})
        end
      end

      request.content_type = 'application/json'
      request['Accept'] = 'application/json'

      req_options = {
          use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if response.code === '401'
        raise Exception, 'Token has expired, Generate a new one before attempting again'
      elsif response.code === '422'
        parse_422_response(response)
      end

      return response
    end
  end

  def http_method(method)
    if method === 'post'
      return Net::HTTP::Post
    elsif method === 'get'
      return Net::HTTP::Get
    elsif method === 'put'
      return Net::HTTP::Put
    elsif method === 'patch'
      return Net::HTTP::Patch
    elsif method === 'delete'
      return Net::HTTP::Delete
    else
      raise ArgumentError, 'Please input a valid HTTP method: ' + method
    end
  end

  def get_lists
    return base_uri('get', 'lists')
  end

  def create_list(name)
    return base_uri('post', 'lists', name)
  end

  #
  def list_info(list_id)
    return base_uri('get', 'lists/' + list_id)
  end

  #
  def update_list(list_id, name)
    return base_uri('patch', 'lists/' + list_id, name)
  end

  #
  def delete_list(list_id)
    return base_uri('delete', 'lists/' + list_id)
  end

  def create_todo(list_id, name)
    return base_uri('post', 'lists/' + list_id + '/items', name)
  end

  def todo_finished(list_id, item_id)
    url_addon = 'lists/' + list_id + '/items/' + item_id + '/finish'
    return base_uri('put', url_addon)
  end

  #
  def delete_item(list_id, item_id)
    url_addon = 'lists/' + list_id + '/items/' + item_id
    return base_uri('delete', url_addon)
  end
end