require 'zulip_machine'

EM.run do
  email = ENV['EMAIL']
  api_key = ENV['API_KEY']

  bot = ZulipMachine::Bot.new(email, api_key)
  bot.start!

  bot.subscribe!(["test-bot"])

  bot.on_private_msg do |from, msg|
    from.send(msg.upcase)
  end

  bot.on_stream_msg do |from, convo, msg|
    convo.send("cool story bro")
  end
end
