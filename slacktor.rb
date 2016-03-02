require "slack/client"
require "json"

def get_swig(client)
  list = JSON.parse(client.channels.list)
  swig = list["channels"].find { |chan| chan["name"] == "dj_swig" }
  if swig
    swig
  else
    puts "ERROR: channel #dj_swig not found!!! sally probably archived it"
  end
end

def run
  puts "Warming up the Slacktor Beam..."
  token = ENV["SLACK_TOKEN"]
  client = Slack::Client.new(token: token)

  swig = get_swig(client)
  channel_id = swig["id"]
  members = swig["members"]

  puts "Slacktor Beam active"
  loop do
    sleep 10

    swig = get_swig(client)
    if swig
      new_members = swig["members"]
      members_missing = members - new_members
      members = (members + new_members).uniq
      if members_missing != []
        puts "Users: #{members_missing.inspect} are trying to leave!"
      end
      members_missing.each do |user_id|
        puts "Re-inviting escapee #{user_id}"
        client.channels.get("channels.invite", channel: channel_id, user: user_id)
      end
    end
  end
end


run
