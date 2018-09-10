require "logger"

require "./imap"

if ARGV.size < 2
    STDERR.puts "Usage: #{PROGRAM_NAME} <username> <password>"
    exit 1
end

imap = Imap::Client.new(host: "imap.gmail.com", port: 993, username: ARGV[0], password: ARGV[1], loglevel: Logger::DEBUG)
mailboxes = imap.list
if mailboxes.includes?("INBOX")
  pp imap.status("INBOX", ["MESSAGES", "RECENT"])

  imap.select("INBOX")
  imap.idle do |name, value|
    puts "#{name} => #{value}"
  end
end

sleep 3
imap.idle_done
imap.close
