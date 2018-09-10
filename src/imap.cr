require "./imap/*"
require "openssl"
require "logger"

module Imap
  class Client
    @caps : Set(String)
    @socket : TCPSocket | OpenSSL::SSL::Socket::Client | Nil = nil
    @logger : Logger

    def initialize(host = "imap.gmail.com", port = 993, username = "", password = "", loglevel = Logger::ERROR)
      @logger = Logger.new(STDOUT)
      @logger.level = loglevel
      @mailboxes = [] of String

      @socket = TCPSocket.new(host, port)
      tls_socket = OpenSSL::SSL::Socket::Client.new(@socket.as(TCPSocket), sync_close: true, hostname: host)
      tls_socket.sync = false
      @socket = tls_socket
      login(username, password)
      # list headers
      # process_mail_headers(command("tag FETCH 1:#{count} (BODY[HEADER])"))

      @caps = capability
    end

    private def socket
      if _socket = @socket
        _socket
      else
        raise "Client socket not opened."
      end
    end

    private def command(command : String, *parameters, &block : String -> Bool)
      command_and_parameter = "tag #{command}"
      params = parameters.join(" ")
      command_and_parameter += " #{params}" if params && params.size > 0
      @logger.info "=====> #{command_and_parameter}"

      socket << command_and_parameter << "\r\n"
      socket.flush

      while (line = socket.gets)
        break unless block.call(line)
      end
    end

    private def command(command : String, *parameters) : Array(String)
      res = [] of String

      command(command, *parameters) do |line|
        if line =~ /^\*/
          res << line
        elsif line =~ /^tag OK/
          res << line
          next false
        elsif line =~ /^tag (BAD|NO)/
          raise "Invalid responce \"#{line}\" received."
        else
          res << line
        end
        true
      end

      res
    end

    private def login(username, password)
      command("login", username, password)
    end

    # Sends a CAPABILITY command
    def capability : Set(String)
      result = command("CAPABILITY")
      Set.new(result.first.split(" "))
    end

    # Sends an IDLE command,
    #  raises exception if server doesn't support IDLE
    def idle
      raise "Server doesn't support IDLE" unless @caps.includes?("IDLE")
      command("IDLE") do |line|
        puts line
        true
      end
    end

    # Sends a SELECT command to select a +mailbox+ so that messages
    # in the +mailbox+ can be accessed.
    def select(mailbox)
      command("SELECT", mailbox)
    end

    # Sends a EXAMINE command to select a +mailbox+ so that messages
    # in the +mailbox+ can be accessed.  Behaves the same as #select(),
    # except that the selected +mailbox+ is identified as read-only.
    def examine(mailbox)
      command("EXAMINE", mailbox)
    end

    # Sends a DELETE command to remove the +mailbox+.
    def delete(mailbox)
      command("DELETE", mailbox)
    end

    # Sends a RENAME command to change the name of the +mailbox+ to
    # +newname+.
    def rename(mailbox, newname)
      command("RENAME", mailbox, newname)
    end


    # Returns an array of mailbox names
    def list : Set(String)
      mailboxes = [] of String
      res = command(%{LIST "" "*"})
      res.each do |line|
        if line =~ /HasNoChildren/
          name = line.match(/"([^"]+)"$/)
          mailboxes << name[1].to_s if name
        end
      end
      # TODO: decode MIME encoded UTF-8 strings
      return Set.new(mailboxes)
    end

    # Sends a STATUS command, and returns the status of the indicated
    # `mailbox`. `attr` is a list of one or more attributes whose
    # statuses are to be requested.  Supported attributes include:
    #
    #   * MESSAGES:: the number of messages in the mailbox.
    #   * RECENT:: the number of recent messages in the mailbox.
    #   * UNSEEN:: the number of unseen messages in the mailbox.
    #
    # The return value is a hash of attributes. For example:
    # ```
    #   p imap.status("inbox", ["MESSAGES", "RECENT"])
    #   #=> {"RECENT"=>0, "MESSAGES"=>44}
    #```
    def status(mailbox, attr : Array(String))
      param = "(#{attr.join(" ")})"
      res = command("STATUS", mailbox, param)
      vals = Hash(String, Int32).new
      counts = res[0].match(/\(([^)]+)\)/)
      if counts && counts[1]
        counts[1].scan(/\w+ \d+/) do |match|
          key, value = match[0].to_s.split(" ", 2)
          vals[key] = value.to_i
        end
      end
      return vals
    end

    private def process_mail_headers(res)
      ip = nil
      from = nil
      res.each do |line|
        if line =~ /^From:/
          from = line.sub(/^From: /, "")
        end
        if line =~ /^Received:/
          ips = line.match(/\[(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\]/)
          if ips
            ip = ips[1].to_s
          end
        end
        if ip && from
          @logger.info "from: #{from} ip: #{ip}"
          from = nil
          ip = nil
        end
      end
    end

    # Closes the imap connection
    def close
      command("LOGOUT") rescue nil
      @socket.close
    end
  end
end
