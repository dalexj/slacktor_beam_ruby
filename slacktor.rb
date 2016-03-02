require "slack/client"
require "json"
require "date"

def log_puts(arg)
  time = Date.today.to_s + " " + Time.now.strftime("%I:%M %p")
  puts "#{time} - #{arg}"
end

def get_swig(client)
  list = JSON.parse(client.channels.list)
  swig = list["channels"].find { |chan| chan["name"] == "dj_swig" }
  if swig
    swig
  else
    log_puts "ERROR: channel #dj_swig not found!!! sally probably archived it"
  end
end

def run
  log_puts "Warming up the Slacktor Beam..."
  token = ENV["SLACK_TOKEN"]
  client = Slack::Client.new(token: token)

  swig = get_swig(client)
  channel_id = swig["id"]
  members = swig["members"]

  log_puts "Slacktor Beam active"
  loop do
    sleep 10

    swig = get_swig(client)
    if swig
      new_members = swig["members"]
      members_missing = members - new_members
      members = (members + new_members).uniq
      if members_missing != []
        log_puts "Users: #{members_missing.inspect} are trying to leave!"
      end
      members_missing.each do |user_id|
        log_puts "Re-inviting escapee #{user_id}"
        client.channels.get("channels.invite", channel: channel_id, user: user_id)
      end
    end
  end
end


run
