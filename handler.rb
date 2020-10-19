load "vendor/bundle/bundler/setup.rb"

require 'twilio-ruby'
require 'firebase'
require 'uri/query_params'

# Utils
def next_response(data: nil)
  {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/xml'
    },
    body: data
  }
end

def get_params(params = '')
  params = params.split('+', 2)
  { action: params[0], data: params[1] || '' }
end

def parse(twilio_data: '')
  data = URI::QueryParams.parse(twilio_data)
  get_params(data['Body'])
end

def format_data(data = '')
  data.strip.gsub('+', ' ')
end

# Handlers

## Global
def greeting
  """Hello there, I\'m *Horrbot* 🧟. I\'ll help you to handle task about coming movies/series to watch.

If you want to know more about me, just check it out:

- */hey*: A friendly information about me 🙂
- */add <name>*: Include a new movie
- */check*: Check all the movies to watch
  """
end

def add_task(client: nil, new_name: '')
  return '😓 - Upss, you forgot the movie\'s name' if new_name === ''
  response = client.push("todos", { name: new_name })
  response.success? ? "🎉 - Cool, The movie called *#{new_name}* has been added successfully!" : '💆 - An error has been triggered, please let us check.'
end

def check_tasks(client: nil)
  response = client.get("todos")
  body = response.body
  
  elements = ''

  body.each { |_, value| elements << "🔜 - *#{value["name"]}* \n"} 

  body.length > 0 ? "👻 Booh!, you have the following macabre movies to kill _hahahahaha!..._ \n\n#{elements}" : '😓 Hey!, you don\'t have movie(s) on the list, let\'s try to add a new one with `/add <MovieNAme>`'
end

def pusher(event:, context:)
  body = parse(twilio_data: event['body'])

  firebase ||= Firebase::Client.new(
    ENV['HORROR_TASK_URL']
  )

  action = body[:action]
  data = format_data(body[:data])

  next_body = ''

  case action
  when '/hey'
    next_body = greeting
  when '/add'
    next_body = add_task(client: firebase, new_name: data)
  when '/check'
    next_body = check_tasks(client: firebase)
  else
    next_body = greeting
  end

  response = Twilio::TwiML::MessagingResponse.new do |res|
    res.message(
      body: next_body
    )
  end
  next_response(data: response.to_s)
end