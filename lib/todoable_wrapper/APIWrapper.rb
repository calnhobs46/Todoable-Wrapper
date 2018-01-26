require 'todoable_wrapper/version'
require 'net/http'
require 'uri'
require 'json'

class APIWrapper
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

  #Authenticate all transactions by providing a username and password
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

  #start a session by getting a token from the authentication call
  def start_session
    response = base_uri('post','authenticate', nil)
    parse_auth_response(response)
    return response
  end

  #Retrieves all lists with list name, src and id
  def get_lists
    return base_uri('get', 'lists')
  end

  #Creates a list when the name is included
  def create_list(name)
    return base_uri('post', 'lists', name)
  end

  #Retrieves the list information, which includes the items' name, src, id
  #and when the item was finished, if available
  def list_info(list_id)
    return base_uri('get', 'lists/' + list_id)
  end

  #Updates the list name
  def update_list(list_id, name)
    return base_uri('patch', 'lists/' + list_id, name)
  end

  #Deletes the list and the list's items
  def delete_list(list_id)
    return base_uri('delete', 'lists/' + list_id)
  end

  #Creates a to do item when the item's name is provided
  def create_todo(list_id, name)
    return base_uri('post', 'lists/' + list_id + '/items', name)
  end

  #Marks the to do item as finished
  def todo_finished(list_id, item_id)
    url_addon = 'lists/' + list_id + '/items/' + item_id + '/finish'
    return base_uri('put', url_addon)
  end

  #Deletes the item
  def delete_item(list_id, item_id)
    url_addon = 'lists/' + list_id + '/items/' + item_id
    return base_uri('delete', url_addon)
  end

  #Saves the token and expires_at date once a token is created
  def parse_auth_response(response)
    json = JSON.parse(response.body)
    @@token = json['token']
    @@expires = json['expires_at']
  end

  #Parses a 422 response by returning an exception with each key and value
  #part of the 422 response's body
  def parse_422_response(response)
    json = JSON.parse(response.body)
    json.each do |key, value|
      raise Exception, "The input value: #{key} is invalid: #{value[0]}"
    end
  end

  #Returns the Net::HTTP method
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

  #Creates the request needed to send an API request, and returns the response
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
end
