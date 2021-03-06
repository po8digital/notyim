# frozen_string_literal: true

# Trinity
module Trinity
  # Encapsulate current request data
  class Current
    attr_accessor :team, :user, :host, :domain
    attr_reader :session

    def initialize(user, request, session)
      @session = session
      @user = user
      @host = request.host
      @domain = request.domain

      detect_team if @user.present?
    end

    def signed_in?
      user.present?
    end

    def detect_team
      # TODO: Remove those magic string
      if @host&.start_with?('team-') && @host&.end_with?('noty.im', 'noty.dev')
        find_team_from_host
      else
        load_default_team_for_user
      end
    rescue StandardError => e
      Bugsnag.notify e
      session[:team] = nil
      raise e
    end

    class << self
      def instance(user, request, session)
        RequestStore.store[:current_request] ||= new(user, request, session)

        current
      end

      def current
        RequestStore.store[:current_request]
      end

      def reset!
        RequestStore.store[:current_request] = nil
      end
    end

    private

    def find_team_from_host
      # TODO: Cache or do domain -> team mapping
      team = TeamService.find_team_from_host @host
      raise 'Forbidden' unless TeamPolicy.can_manage?(team, user) && TeamPolicy.can_view?(team, user)

      session[:team] = team.id.to_s
      @team = team
    end

    def load_default_team_for_user
      unless session[:team]
        @team = @user.default_team
        session[:team] = @user.default_team.id.to_s

        return
      end

      load_team_from_session
    end

    def load_team_from_session
      # If session already has a team, ensure user can see this team
      @team = Team.find(session[:team])

      unless can_view_team?
        @team = session[:team] = nil
        return head(:forbidden)
      end

      session[:team] = @team.id.to_s
    rescue Mongoid::Errors::DocumentNotFound => e
      Bugsnag.notify e

      not_found
    end

    def can_view_team?
      TeamPolicy.can_manage?(team, user) || TeamPolicy.can_view?(team, user)
    end
  end
end
