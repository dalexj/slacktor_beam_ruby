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
    log_puts "ERROR: channel #dj_swig not found, must have been admin deleted"
    log_puts "Re-run slacktor beam once the channel is recreated"
    exit 0
  end
end

def reinvite_missing(client, swig, members, archive)
  new_members = swig["members"]
  members_missing = members - new_members
  members = (members + new_members).uniq
  if members_missing != [] && !archive
    log_puts "Users: #{members_missing.inspect} are trying to leave!"
  end
  members_missing.each do |user_id|
    log_puts "Re-inviting escapee #{user_id}"
    client.channels.get("channels.invite", channel: swig["id"], user: user_id)
  end
  members
end

def run
  log_puts "Warming up the Slacktor Beam..."
  token = ENV["SLACK_TOKEN"]
  client = Slack::Client.new(token: token)

  swig = get_swig(client)
  members = swig["members"]

  log_puts "Slacktor Beam active"
  loop do
    sleep 10

    swig = get_swig(client)
    if swig
      if swig["is_archived"]
        log_puts "The swig has been archived, un-archiving channel..."
        client.channels.get("channels.unarchive", channel: swig["id"])
        log_puts "The swig has been unarchived"
        log_puts "Re-inviting all members..."
        members = reinvite_missing(client, swig, members, true)
      else
        members = reinvite_missing(client, swig, members, false)
      end
    end
  end
end


run
