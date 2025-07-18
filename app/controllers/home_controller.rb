class HomeController < ApplicationController
  def index
    # Find active tournament
    @active_tournament = Tournament.active.first

    # If no active tournament, find the next upcoming one
    @upcoming_tournament = Tournament.upcoming.order(:start_date).first unless @active_tournament

    # For signed-in users with active tournament, get their upcoming matches
    if user_signed_in? && @active_tournament
      @user_matches = current_user.matches.joins(:round)
                                 .where(rounds: { tournament: @active_tournament })
                                 .where(status: [ "upcoming", "active" ])
                                 .includes(:round, :team_a, :team_b, :match_players)
                                 .order("rounds.round_number ASC, scheduled_time ASC")
    end
  end
end
