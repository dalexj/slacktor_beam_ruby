require "slack/client"
require "json"
require "date"

class SlacktorBeam
  def initialize
    log_puts "Warming up the Slacktor Beam..."

    @channel_name = "dj_swig"
    @client = Slack::Client.new(token: ENV["SLACK_TOKEN"])

    lookup_swig
    @members = @swig["members"]

    log_puts "Slacktor Beam active"
  end

  def log_puts(arg)
    time = Date.today.to_s + " " + Time.now.strftime("%I:%M %p")
    puts "#{time} - #{arg}"
  end

  def lookup_swig
    list = JSON.parse(@client.channels.list)
    @swig = list["channels"].find { |chan| chan["name"] == @channel_name }
    check_for_admin_abuse!
  end

  def check_for_admin_abuse!
    if !@swig
      log_puts "ERROR: channel ##{@channel_name} not found, must have been deleted by an admin"
      log_puts "Re-run slacktor beam once the channel is recreated"
      exit 0
    end
  end

  def run
    lookup_swig
    if @swig["is_archived"]
      log_puts "The swig has been archived, un-archiving channel..."
      unarchive_swig
      log_puts "The swig has been unarchived"
      log_puts "Re-inviting all members..."
      reinvite_missing(true)
    else
      reinvite_missing(false)
    end
  end

  def unarchive_swig
    @client.channels.get("channels.unarchive", channel: @swig["id"])
  end

  def reinvite_missing(archive)
    new_members = @swig["members"]
    members_missing = @members - new_members
    @members = (@members + new_members).uniq
    if members_missing != [] && !archive
      log_puts "Users: #{members_missing.inspect} are trying to leave!"
    end
    members_missing.each do |user_id|
      log_puts "Re-inviting escapee #{user_id}"
      @client.channels.get("channels.invite", channel: @swig["id"], user: user_id)
    end
  end
end

beam = SlacktorBeam.new
loop do
  sleep 10
  beam.run
end
