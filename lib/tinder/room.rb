module Tinder
  # A campfire room
  class Room
    attr_reader :id, :name

    def initialize(connection, attributes = {})
      @connection = connection
      @id = attributes['id']
      @name = attributes['name']
      @loaded = false
    end

    # Join the room
    # POST /room/#{id}/join.xml
    # For whatever reason, #join() and #leave() are still xml endpoints
    # whereas elsewhere in this API we're assuming json :\
    def join
      post 'join', 'xml'
    end

    # Leave a room
    # POST /room/#{id}/leave.xml
    def leave
      post 'leave', 'xml'
    end

    # Get the url for guest access
    def guest_url
      "#{@connection.uri}/#{guest_invite_code}" if guest_access_enabled?
    end

    def guest_access_enabled?
      load
      @open_to_guests ? true : false
    end

    # The invite code use for guest
    def guest_invite_code
      load
      @active_token_value
    end

    # Change the name of the room
    def name=(name)
      update :name => name
    end
    alias_method :rename, :name=

    # Change the topic
    def topic=(topic)
      update :topic => topic
    end

    def update(attrs)
      connection.put("/room/#{@id}.json", {:room => attrs})
    end

    # Get the current topic
    def topic
      load
      @topic
    end

    # Lock the room to prevent new users from entering and to disable logging
    def lock
      post 'lock'
    end

    # Unlock the room
    def unlock
      post 'unlock'
    end

    # Post a new message to the chat room
    def speak(message, options = {})
      send_message(message)
    end

    def paste(message)
      send_message(message, 'PasteMessage')
    end

    def play(sound)
      send_message(sound, 'SoundMessage')
    end

    def tweet(url)
      send_message(url, 'TweetMessage')
    end

    # Get the list of users currently chatting for this room
    def users
      reload!
      @users
    end

    # return the user with the given id; if it isn't in our room cache, do a request to get it
    def user(id)
      if id
        user = users.detect {|u| u[:id] == id }
        unless user
          user_data = connection.get("/users/#{id}.json")
          user = user_data && user_data[:user]
        end
        user[:created_at] = Time.parse(user[:created_at])
        user
      end
    end

    # Get the transcript for the given date (Returns a hash in the same format as #listen)
    #
    #   room.transcript(room.available_transcripts.first)
    #   #=> [{:message=>"foobar!",
    #         :user_id=>"99999",
    #         :person=>"Brandon",
    #         :id=>"18659245",
    #         :timestamp=>=>Tue May 05 07:15:00 -0700 2009}]
    #
    # The timestamp slot will typically have a granularity of five minutes.
    #
    def transcript(transcript_date)
      url = "/room/#{@id}/transcript/#{transcript_date.to_date.strftime('%Y/%m/%d')}.json"
      connection.get(url)['messages'].map do |room|
        { :id => room['id'],
          :user_id => room['user_id'],
          :message => room['body'],
          :timestamp => Time.parse(room['created_at']) }
      end
    end

    def upload(file, content_type = nil, filename = nil)
      require 'mime/types'
      content_type ||= MIME::Types.type_for(filename || file)
      raw_post(:uploads, { :upload => Faraday::UploadIO.new(file, content_type, filename) })
    end

    # Get the list of latest files for this room
    def files(count = 5)
      get(:uploads)['uploads'].map { |u| u['full_url'] }
    end

  protected

    def load
      reload! unless @loaded
    end

    def reload!
      attributes = connection.get("/room/#{@id}.json")['room']

      @id = attributes['id']
      @name = attributes['name']
      @topic = attributes['topic']
      @full = attributes['full']
      @open_to_guests = attributes['open_to_guests']
      @active_token_value = attributes['active_token_value']
      @users = attributes['users']

      @loaded = true
    end

    def send_message(message, type = 'TextMessage')
      post 'speak', {:message => {:body => message, :type => type}}
    end

    def get(action)
      connection.get(room_url_for(action))
    end

    def post(action, body = nil)
      connection.post(room_url_for(action), body)
    end

    def raw_post(action, body = nil)
      connection.raw_post(room_url_for(action), body)
    end

    def room_url_for(action, format="json")
      "/room/#{@id}/#{action}.#{format}"
    end

    def connection
      @connection
    end
  end
end
