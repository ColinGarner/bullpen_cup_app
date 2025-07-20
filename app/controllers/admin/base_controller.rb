class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :set_admin_group_context
  before_action :ensure_admin_access!

  layout "admin/application"

  protected

  def set_admin_group_context
    # Get group from URL params
    if params[:group_slug].present?
      @current_group = Group.find_by(slug: params[:group_slug])
      unless @current_group
        redirect_to select_group_path, alert: "Group not found."
        return
      end

      # Set the group context
      Current.user = current_user
      Current.group = @current_group
      session[:current_group_id] = @current_group.id
    else
      redirect_to select_group_path, alert: "Please select a group to access admin features."
    end
  end

  def ensure_admin_access!
    # Allow global admins to access any group
    return if current_user&.admin?

    # For group admins, verify they have admin access to the current group
    unless current_user&.group_admin?(current_group)
      redirect_to root_path, alert: "Access denied. You must be an admin of #{current_group.name} to access this area."
    end
  end

  # Helper methods for views and controllers
  def current_group
    @current_group || Current.group
  end

  def user_is_global_admin?
    current_user&.admin?
  end

  def user_is_group_admin?
    current_user&.group_admin?(current_group)
  end

  # Auto-scoped route helpers for convenience
  def scoped_admin_tournament_path(tournament)
    admin_tournament_path(group_slug: current_group.slug, id: tournament)
  end

  def scoped_edit_admin_tournament_path(tournament)
    edit_admin_tournament_path(group_slug: current_group.slug, id: tournament)
  end

  def scoped_admin_tournaments_path
    admin_tournaments_path(group_slug: current_group.slug)
  end

  def scoped_new_admin_tournament_path
    new_admin_tournament_path(group_slug: current_group.slug)
  end

  # Team helpers
  def scoped_new_admin_tournament_team_path(tournament)
    new_admin_tournament_team_path(group_slug: current_group.slug, tournament_id: tournament)
  end

  def scoped_admin_tournament_team_path(tournament, team)
    admin_tournament_team_path(group_slug: current_group.slug, tournament_id: tournament, id: team)
  end

  def scoped_edit_admin_tournament_team_path(tournament, team)
    edit_admin_tournament_team_path(group_slug: current_group.slug, tournament_id: tournament, id: team)
  end

  def scoped_admin_tournament_teams_path(tournament)
    admin_tournament_teams_path(group_slug: current_group.slug, tournament_id: tournament)
  end

  def scoped_admin_teams_path
    admin_teams_path(group_slug: current_group.slug)
  end

  def scoped_admin_tournaments_path
    admin_tournaments_path(group_slug: current_group.slug)
  end

  # Round helpers
  def scoped_new_admin_tournament_round_path(tournament)
    new_admin_tournament_round_path(group_slug: current_group.slug, tournament_id: tournament)
  end

  def scoped_admin_tournament_round_path(tournament, round)
    admin_tournament_round_path(group_slug: current_group.slug, tournament_id: tournament, id: round)
  end

  def scoped_edit_admin_tournament_round_path(tournament, round)
    edit_admin_tournament_round_path(group_slug: current_group.slug, tournament_id: tournament, id: round)
  end

  def scoped_admin_tournament_round_update_path(tournament, round)
    admin_tournament_round_path(group_slug: current_group.slug, tournament_id: tournament, id: round)
  end

  def scoped_admin_tournament_rounds_path(tournament)
    admin_tournament_rounds_path(group_slug: current_group.slug, tournament_id: tournament)
  end

  # Round action helpers
  def scoped_start_admin_tournament_round_path(tournament, round)
    start_admin_tournament_round_path(group_slug: current_group.slug, tournament_id: tournament, id: round)
  end

  def scoped_complete_admin_tournament_round_path(tournament, round)
    complete_admin_tournament_round_path(group_slug: current_group.slug, tournament_id: tournament, id: round)
  end

  def scoped_cancel_admin_tournament_round_path(tournament, round)
    cancel_admin_tournament_round_path(group_slug: current_group.slug, tournament_id: tournament, id: round)
  end

  # Match helpers (matches are nested under rounds)
  def scoped_new_admin_tournament_round_match_path(tournament, round)
    new_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round)
  end

  def scoped_admin_tournament_round_match_path(tournament, round, match)
    admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match)
  end

  def scoped_admin_tournament_round_matches_path(tournament, round)
    admin_tournament_round_matches_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round)
  end

  def scoped_players_admin_tournament_round_match_path(tournament, round, match)
    players_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match)
  end

  def scoped_search_courses_admin_tournament_round_matches_path(tournament, round)
    search_courses_admin_tournament_round_matches_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round)
  end

  def scoped_add_player_admin_tournament_round_match_path(tournament, round, match)
    add_player_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match)
  end

  def scoped_remove_player_admin_tournament_round_match_path(tournament, round, match, options = {})
    remove_player_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match, **options)
  end

  def scoped_edit_admin_tournament_round_match_path(tournament, round, match)
    edit_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match)
  end

  def scoped_start_admin_tournament_round_match_path(tournament, round, match)
    start_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match)
  end

  def scoped_cancel_admin_tournament_round_match_path(tournament, round, match)
    cancel_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match)
  end

  def scoped_complete_admin_tournament_round_match_path(tournament, round, match)
    complete_admin_tournament_round_match_path(group_slug: current_group.slug, tournament_id: tournament, round_id: round, id: match)
  end

  helper_method :current_group, :user_is_global_admin?, :user_is_group_admin?,
                :scoped_admin_tournament_path, :scoped_edit_admin_tournament_path,
                :scoped_admin_tournaments_path, :scoped_new_admin_tournament_path,
                :scoped_new_admin_tournament_team_path, :scoped_admin_tournament_team_path,
                :scoped_edit_admin_tournament_team_path, :scoped_admin_tournament_teams_path,
                :scoped_admin_teams_path, :scoped_admin_tournaments_path, :scoped_new_admin_tournament_round_path,
                :scoped_admin_tournament_round_path, :scoped_edit_admin_tournament_round_path,
                :scoped_admin_tournament_rounds_path, :scoped_start_admin_tournament_round_path,
                :scoped_complete_admin_tournament_round_path, :scoped_cancel_admin_tournament_round_path,
                :scoped_admin_tournament_round_update_path, :scoped_new_admin_tournament_round_match_path,
                :scoped_admin_tournament_round_match_path, :scoped_admin_tournament_round_matches_path,
                :scoped_players_admin_tournament_round_match_path, :scoped_search_courses_admin_tournament_round_matches_path,
                :scoped_add_player_admin_tournament_round_match_path, :scoped_remove_player_admin_tournament_round_match_path,
                :scoped_edit_admin_tournament_round_match_path, :scoped_start_admin_tournament_round_match_path,
                :scoped_cancel_admin_tournament_round_match_path, :scoped_complete_admin_tournament_round_match_path
end
