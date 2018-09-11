require "./spec_helper"

describe Imap do
  # TODO: Write tests

  it "should count emails in mailbox" do
    imap = Imap::Client.new(host: "127.0.0.1", port: 3993,
                            username: "test", password: "test",
                            verify: OpenSSL::SSL::VerifyMode::NONE)
    mailboxes = imap.list
    if mailboxes.size > 0
      mailbox = mailboxes.first
      message_count = imap.status(mailbox, ["MESSAGES"])["MESSAGES"]
      puts "There are #{message_count} message in #{mailbox}"
    end
    imap.close
  end
end
