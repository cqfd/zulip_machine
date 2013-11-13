require "zulip_machine/version"

require 'em-http'
require 'json'

module EM::Deferrable
  def bind(&f)
    d = EM::DefaultDeferrable.new
    callback do |a|
      f.call(a).callback { |b| d.succeed(b) }.errback { |e| d.fail(e) }
    end
    errback { |e| d.fail(e) }
    d
  end
  def map(&f)
    d = EM::DefaultDeferrable.new
    callback { |a| d.succeed(f.call(a)) }
    errback  { |e| d.fail(e) }
    d
  end
end

module ZulipMachine
  ENDPOINT = "https://api.zulip.com/v1"

  User = Struct.new(:bot, :deets) do
    def send(msg)
      bot.send_private_msg(email, msg)
    end
  end
  Conversation = Struct.new(:bot, :stream, :subject) do
    def send(msg)
      bot.send_stream_msg(stream, subject, msg)
    end
  end

  class Bot
    def initialize(email, api_key)
      @email = email
      @api_key = api_key
      @private_cbs = []
      @stream_cbs = []
      @presence_cbs = []
    end

    def start!
      post("/register").callback do |r|
        fetch_events(r["queue_id"], r["last_event_id"])
      end
    end

    def send_private_msg(to_whom, msg)
      post("/messages", type: "private", to: to_whom, content: msg)
    end

    def send_stream_msg(to, subject, msg)
      post("/messages", type: "stream", to: to, subject: subject, content: msg)
    end

    def get_subscriptions
      get("/users/me/subscriptions")
    end

    def subscribe!(streams)
      streams = streams.map { |name| { name: name } }
      patch("/users/me/subscriptions", add: JSON.unparse(streams))
    end

    def unsubscribe!(streams)
      patch("/users/me/subscriptions", subscriptions: JSON.unparse(streams))
    end

    def on_private_msg(&cb)
      @private_cbs << cb
    end
    def on_stream_msg(&cb)
      @stream_cbs << cb
    end
    def on_presence(&cb)
      @presence_cbs << cb
    end

    def fetch_events(q_id, event_id)
      get("/events", queue_id: q_id, last_event_id: event_id).callback do |r|
        r["events"].each { |e| handle_event(e) }
        event_id = r["events"].map { |e| e["id"] }.max
        fetch_events(q_id, event_id)
      end.errback do |c|
        fetch_events(q_id, event_id)
      end
    end

    def handle_event(e)
      case e["type"]
      when "message"
        deets = e["message"]
        case deets["type"]
        when "private"
          unless deets["sender_email"] == @email
            from = User.new(self, deets)
            msg = deets["content"]
            @private_cbs.each { |cb| cb.call(from, msg) }
          end
        when "stream"
          unless deets["sender_email"] == @email
            from = User.new(self, deets)
            stream = deets["display_recipient"]
            subject = deets["subject"]
            convo = Conversation.new(self, stream, subject)
            msg = deets["content"]
            @stream_cbs.each { |cb| cb.call(from, convo, msg) }
          end
        end
      when "presence"
        who = User.new(self, e)
        presence = e["presence"]
        @presence_cbs.each { |cb| cb.call(who, presence) }
      end
    end

    def get(path, params = nil)
      req(path).get(
        query: params, 
        head: auth,
        inactivity_timeout: 0
      ).map { |c| JSON.parse(c.response) }
    end

    def post(path, params = nil)
      req(path).post(
        body: params, 
        head: auth,
        inactivity_timeout: 0
      ).map { |c| JSON.parse(c.response) }
    end

    def patch(path, params = nil)
      req(path).patch(
        body: params,
        head: auth,
        inactivity_timeout: 0
      ).map { |c| JSON.parse(c.response) }
    end

    def req(path)
      EM::HttpRequest.new(ENDPOINT + path)
    end

    def auth
      { authorization: [@email, @api_key] }
    end
  end
end

