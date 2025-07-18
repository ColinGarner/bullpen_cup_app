class Admin::TeamsController < Admin::BaseController
  before_action :set_tournament, except: []
  before_action :set_team, only: [ :show, :edit, :update, :destroy, :add_player, :remove_player ]

  def index
    if @tournament
      # Nested route: show teams for specific tournament
      @teams = @tournament.teams.includes(:captain, :team_memberships, :players).by_name
    else
      # Standalone route: show all teams across tournaments
      @teams = Team.includes(:tournament, :captain, :team_memberships, :players)
                   .order("tournaments.name, teams.name")
      @teams = @teams.joins(:tournament).where(tournaments: { name: params[:search] }) if params[:search].present?
    end
  end

  def show
    @players = @team.players.includes(:team_memberships)
    @available_users = User.where.not(id: @team.player_ids).order(:email)
  end

  def new
    @team = @tournament.teams.build
    @available_captains = User.order(:email)
  end

  def create
    @team = @tournament.teams.build(team_params)

    if @team.save
      redirect_to admin_tournament_path(@tournament),
                  notice: "Team was successfully created."
    else
      # Log errors for debugging
      Rails.logger.debug "Team creation failed: #{@team.errors.full_messages.join(', ')}"
      @available_captains = User.order(:email)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_captains = User.order(:email)
  end

  def update
    if @team.update(team_params)
      redirect_to admin_tournament_team_path(@tournament, @team),
                  notice: "Team was successfully updated."
    else
      @available_captains = User.order(:email)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team.destroy
    redirect_to admin_tournament_path(@tournament),
                notice: "Team was successfully deleted."
  end

  def add_player
    @user = User.find(params[:user_id])

    if @team.add_player(@user)
      redirect_to admin_tournament_team_path(@tournament, @team),
                  notice: "#{@user.display_name} was added to the team."
    else
      redirect_to admin_tournament_team_path(@tournament, @team),
                  alert: "Could not add #{@user.display_name} to the team."
    end
  end

  def remove_player
    @user = User.find(params[:user_id])

    if @team.remove_player(@user)
      redirect_to admin_tournament_team_path(@tournament, @team),
                  notice: "#{@user.display_name} was removed from the team."
    else
      redirect_to admin_tournament_team_path(@tournament, @team),
                  alert: "Could not remove #{@user.display_name} from the team. Captains cannot be removed."
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id]) if params[:tournament_id]
  end

  def set_team
    if @tournament
      @team = @tournament.teams.find(params[:id])
    else
      @team = Team.find(params[:id])
    end
  end

  def team_params
    params.require(:team).permit(:name, :captain_id)
  end
end
