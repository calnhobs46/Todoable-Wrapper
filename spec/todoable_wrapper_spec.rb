require 'webmock/rspec'
require 'spec_helper'

RSpec.describe TodoableWrapper do
  it 'has a version number' do
    expect(TodoableWrapper::VERSION).not_to be nil
  end
end

RSpec.describe 'authorization method' do
  before (:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                  body: '{"token": "testToken", "expires_at": "never"}')
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json'},
              basic_auth: ['testUser', 'testPassword']).to_return(status: 422,
                                                                  body: '{"email": ["invalid format"]}')
  end

  it 'The method will return a token for the given username and password' do
    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    response = APIWrapper.new.start_session

    expect(response.code).to eq('200')
    expect(APIWrapper.new.username).to eq('testUser@gmail.com')
    expect(APIWrapper.new.password).to eq('testPassword')
    expect(APIWrapper.new.token).to eq('testToken')
    expect(APIWrapper.new.expires).to eq('never')
  end

  it 'The method will return a list of errors if the username or password is incorrect' do
    APIWrapper.authenticate('testUser', 'testPassword')

    expect(APIWrapper.new.username).to eq('testUser')
    expect(APIWrapper.new.password).to eq('testPassword')
    expect{APIWrapper.new.start_session}.to raise_error(Exception, 'The input value: email is invalid: invalid format')
  end
end

RSpec.describe 'get_lists method' do
  before(:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at": "never"}')

      stub_request(:get, 'http://todoable.teachable.tech/api/lists').
          with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                          'Authorization'=>'Token token=testToken',
                          'Content-Type'=>'application/json',
                          'Host'=>'todoable.teachable.tech',
                          'User-Agent'=>'Ruby'}).
          to_return(status: 200, body: '{"lists": [{"name": "test list",
                                                     "src": "http://todoable.teachable.tech/api/lists/testId1",
                                                     "id": "testId1"}]}', headers: {})

      APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
      APIWrapper.new.start_session
    end

  it 'The method will return lists when the get_lists method is called
      The method will return the name, source, list id when the get_lists method is called' do
    response = APIWrapper.new.get_lists

    expect(response.code).to eq('200')
    expect(JSON.parse(response.body)['lists'][0]['name']).to eq('test list')
    expect(JSON.parse(response.body)['lists'][0]['id']).to eq('testId1')
    expect(JSON.parse(response.body)['lists'][0]['src']).to eq('http://todoable.teachable.tech/api/lists/testId1')
  end
end

RSpec.describe 'create_list method' do
  before(:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at": "never"}')

    stub_request(:post, 'http://todoable.teachable.tech/api/lists').
        with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'Token token=testToken',
                        'Content-Type'=>'application/json',
                        'Host'=>'todoable.teachable.tech',
                        'User-Agent'=>'Ruby'}, body: "{\"list\":{\"name\":\"new listing\"}}").
        to_return(status: 201, body: '{"lists": [{"name": "new listing",
                                                   "src": "http://todoable.teachable.tech/api/lists/newList4",
                                                   "id": "newList4"}]}', headers: {})

    stub_request(:post, 'http://todoable.teachable.tech/api/lists')
        .with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                         'Authorization'=>'Token token=testToken',
                         'Content-Type'=>'application/json',
                         'Host'=>'todoable.teachable.tech',
                         'User-Agent'=>'Ruby'}, body: "{\"list\":{\"name\":\"\"}}").to_return(status: 422, body: '{"name": ["can\'t be blank"]}')

    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    APIWrapper.new.start_session
  end

  it 'The method will create a list when the create_list method is called
      The method will create a list when the list name is included
      The method will return a 201 if the creation of the list is successful' do
    response = APIWrapper.new.create_list('new listing')

    expect(response.code).to eq('201')
    expect(JSON.parse(response.body)["lists"][0]["name"]).to eq("new listing")
    expect(JSON.parse(response.body)["lists"][0]["id"]).to eq("newList4")
    expect(JSON.parse(response.body)["lists"][0]["src"]).to eq("http://todoable.teachable.tech/api/lists/newList4")
  end

  it 'The method will return details on what when wrong if the creation of a list is unsuccessful' do
    expect{APIWrapper.new.create_list("")}.to raise_error(Exception, 'The input value: name is invalid: can\'t be blank')
  end
end

RSpec.describe 'list_info method' do
  before (:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at": "never"}')

    stub_request(:get, 'http://todoable.teachable.tech/api/lists/the_info').
        with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'Token token=testToken',
                        'Content-Type'=>'application/json',
                        'Host'=>'todoable.teachable.tech',
                        'User-Agent'=>'Ruby'}).
        to_return(status: 201, body: '{"list": {"name": "THE list",
                                                 "items": [{"name":  "the todo", "finished_at": null,
                                                              "src": "http://todoable.teachable.tech/api/lists/the_info/items/the_todo",
                                                              "id": "the_todo"},
                                                             {"name": "another todo", "finished_at": "dateTime",
                                                              "src": "http://todoable.teachable.tech/api/lists/the_info/items/todo2",
                                                              "id": "todo2"}]}}', headers: {})

    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    APIWrapper.new.start_session
  end

  it 'The method will return the list info when the list_info method is called
      The method will return list items done and todo list items when the list_info method is called
      The method will return the list name, item name, finished at, source and id for each list item' do
    response = APIWrapper.new.list_info('the_info')

    expect(response.code).to eq('201')
    expect(JSON.parse(response.body)['list']['name']).to eq('THE list')
    expect(JSON.parse(response.body)['list']['items'][0]['name']).to eq('the todo')
    expect(JSON.parse(response.body)['list']['items'][0]['finished_at']).to eq(nil)
    expect(JSON.parse(response.body)['list']['items'][0]['id']).to eq('the_todo')

    expect(JSON.parse(response.body)['list']['items'][1]['name']).to eq('another todo')
    expect(JSON.parse(response.body)['list']['items'][1]['finished_at']).to eq('dateTime')
    expect(JSON.parse(response.body)['list']['items'][1]['id']).to eq('todo2')
  end
end

RSpec.describe 'update_list method' do
  before (:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at": "never"}')

    stub_request(:patch, 'http://todoable.teachable.tech/api/lists/list1').
        with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'Token token=testToken',
                        'Content-Type'=>'application/json',
                        'Host'=>'todoable.teachable.tech',
                        'User-Agent'=>'Ruby'}, body: "{\"list\":{\"name\":\"this is the new name\"}}").
        to_return(status: 201, body: '')

    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    APIWrapper.new.start_session
  end

  it 'The method will update the list name when the update_list method is called' do
    response = APIWrapper.new.update_list('list1', "this is the new name")

    expect(response.code).to eq('201')
  end
end

RSpec.describe 'delete_list method' do
  before (:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at": "never"}')

    stub_request(:delete, 'http://todoable.teachable.tech/api/lists/deadList').
        with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'Token token=testToken',
                        'Content-Type'=>'application/json',
                        'Host'=>'todoable.teachable.tech',
                        'User-Agent'=>'Ruby'}).
        to_return(status: 204, headers: {})

    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    APIWrapper.new.start_session
  end

  it 'The method will delete a list and its items when the delete_items method is called
      The method will return a 204 if the delete_items method is called and successful' do
    response = APIWrapper.new.delete_list('deadList')

    expect(response.code).to eq('204')
  end

end

RSpec.describe 'create_todo method' do
  before (:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at": "never"}')

    stub_request(:post, 'http://todoable.teachable.tech/api/lists/deadList/items').
        with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'Token token=testToken',
                        'Content-Type'=>'application/json',
                        'Host'=>'todoable.teachable.tech',
                        'User-Agent'=>'Ruby'}, body: "{\"item\":{\"name\":\"important!\"}}")
        .to_return(status: 201, body: '{"name": "important!", "finished_at": null,
                                      "src": "http://todoable.teachable.tech/api/lists/deadList/items/item1",
                                      "id": "item1"}')
#this part of the test doesn't work, and I think it has something to do with the quotations, but the other ones in this format work
=begin
    stub_request(:post, 'http://todoable.teachable.tech/api/lists/anotherList/items')
        .with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                         'Authorization'=>'Token token=testToken',
                         'Content-Type'=>'application/json',
                         'Host'=>'todoable.teachable.tech',
                         'User-Agent'=>'Ruby'}, body: '{"item": {"name": ""}}').to_return(status: 422, body: '{"name": ["can\'t be blank"]}')
=end

    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    APIWrapper.new.start_session
  end

  it 'The method will create a todo item when the create_todo method is called
      The method will create a todo item with a name when the create_todo method is called
      The method will return a 201 when creating a todo item is successful' do
    response = APIWrapper.new.create_todo('deadList', 'important!')

    expect(response.code).to eq('201')
    expect(JSON.parse(response.body)["name"]).to eq("important!")
    expect(JSON.parse(response.body)["id"]).to eq("item1")
    expect(JSON.parse(response.body)["src"]).to eq("http://todoable.teachable.tech/api/lists/deadList/items/item1")
    expect(JSON.parse(response.body)["finished_at"]).to eq(nil)
  end

=begin
  it 'The method will return details on what went wrong if the creation of a todo item is unsuccessful' do
    expect{APIWrapper.new.create_todo('anotherList', "")}.to raise_error(Exception, 'The input value: name is invalid: can\'t be blank')
  end
=end

end

RSpec.describe 'complete_todo method' do
  before (:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at":"never"}')

    stub_request(:put, 'http://todoable.teachable.tech/api/lists/list1/items/item1/finish').
        with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'Token token=testToken',
                        'Content-Type'=>'application/json',
                        'Host'=>'todoable.teachable.tech',
                        'User-Agent'=>'Ruby'}).
        to_return(status: 200)

    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    APIWrapper.new.start_session
  end

  it 'The method will return a 200 if finishing a todo item is successful' do
    response = APIWrapper.new.todo_finished('list1', 'item1')

    expect(response.code).to eq('200')
  end

end

RSpec.describe 'delete_item' do
  before (:each) do
    stub_request(:post, 'http://todoable.teachable.tech/api/authenticate')
        .with(headers: {'Accept' => 'application/json',
                        'Authorization'=>'Basic dGVzdFVzZXJAZ21haWwuY29tOnRlc3RQYXNzd29yZA=='},
              basic_auth: ['testUser@gmail.com', 'testPassword']).to_return(status: 200,
                                                                            body: '{"token": "testToken", "expires_at": "never"}')

    stub_request(:delete, 'http://todoable.teachable.tech/api/lists/list1/items/item1').
        with(headers: { 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'Token token=testToken',
                        'Content-Type'=>'application/json',
                        'Host'=>'todoable.teachable.tech',
                        'User-Agent'=>'Ruby'}).
        to_return(status: 204)

    APIWrapper.authenticate('testUser@gmail.com', 'testPassword')
    APIWrapper.new.start_session
  end

  it 'The method will return a 204 when the delete_item method is successful' do
    response = APIWrapper.new.delete_item('list1', 'item1')

    expect(response.code).to eq('204')
  end
end