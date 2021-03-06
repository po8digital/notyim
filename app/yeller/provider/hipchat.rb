# frozen_string_literal: true

require_relative 'base'

module Yeller
  module Provider
    class Hipchat < Base
      Yeller::Provider.register(self)

      configure do
        label! 'Room'
      end

      # Send out notification for an incident. This is
      # a complex logic including
      #   - generate the message
      #   - fanout the message to receiver
      # @param Receiver receiver
      # @param Incident incident
      def self.notify_incident(incident, receiver)
        client = HipChat::Client.new(receiver.handler, api_version: 'v2')
        incident = decorate(incident)
        # #{incident.short_summary_plain}
        body = <<~HEREDOC
          #{incident.subject}
           Service: #{incident.check.uri}
          Incident Detail: #{incident.url}
           Reason: #{incident.reason}
        HEREDOC

        client[receiver.name].send("noty - [#{incident.status} alert]", body, message_format: 'text', color: incident.open? ? 'red' : 'green')
      end
    end
  end
end
