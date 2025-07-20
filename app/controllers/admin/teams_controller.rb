class Admin::TeamsController < Admin::BaseController
  before_action :set_tournament, except: [ :index ]
  before_action :set_team, only: [ :show, :edit, :update, :destroy, :add_player, :remove_player ]

  def index
    # Show all teams across tournaments for the current group
    @teams = Team.joins(:tournament)
                 .where(tournaments: { group: current_group })
                 .includes(:tournament, :captain, :team_memberships, :players)
                 .order("tournaments.name, teams.name")

    if params[:search].present?
      @teams = @teams.where("tournaments.name ILIKE ? OR teams.name ILIKE ?",
                           "%#{params[:search]}%", "%#{params[:search]}%")
    end
  end

  def show
    @players = @team.players.includes(:team_memberships)
    @available_users = current_group.users.where.not(id: @team.player_ids).order(:first_name, :last_name)
  end

  def new
    @team = @tournament.teams.build
    @available_captains = current_group.users.order(:first_name, :last_name)
  end

  def create
    @team = @tournament.teams.build(team_params)

    if @team.save
      redirect_to scoped_admin_tournament_path(@tournament),
                  notice: "Team was successfully created."
    else
      @available_captains = current_group.users.order(:first_name, :last_name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_captains = current_group.users.order(:first_name, :last_name)
  end

  def update
    if @team.update(team_params)
      redirect_to scoped_admin_tournament_team_path(@tournament, @team),
                  notice: "Team was successfully updated."
    else
      @available_captains = current_group.users.order(:first_name, :last_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team.destroy
    redirect_to scoped_admin_tournament_path(@tournament),
                notice: "Team was successfully deleted."
  end

  def add_player
    @user = current_group.users.find(params[:user_id])

    if @team.add_player(@user)
      redirect_to scoped_admin_tournament_team_path(@tournament, @team),
                  notice: "#{@user.display_name} was added to the team."
    else
      redirect_to scoped_admin_tournament_team_path(@tournament, @team),
                  alert: "Could not add #{@user.display_name} to the team."
    end
  end

  def remove_player
    @user = current_group.users.find(params[:user_id])

    if @team.remove_player(@user)
      redirect_to scoped_admin_tournament_team_path(@tournament, @team),
                  notice: "#{@user.display_name} was removed from the team."
    else
      redirect_to scoped_admin_tournament_team_path(@tournament, @team),
                  alert: "Could not remove #{@user.display_name} from the team. Captains cannot be removed."
    end
  end

  private

  def set_tournament
    @tournament = current_group.tournaments.find(params[:tournament_id]) if params[:tournament_id]
  rescue ActiveRecord::RecordNotFound
    redirect_to scoped_admin_tournaments_path,
                alert: "Tournament not found in #{current_group.name}."
  end

  def set_team
    if @tournament
      @team = @tournament.teams.find(params[:id])
    else
      @team = Team.joins(:tournament).where(tournaments: { group: current_group }).find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_back(fallback_location: scoped_admin_teams_path,
                  alert: "Team not found in #{current_group.name}.")
  end

  def team_params
    params.require(:team).permit(:name, :captain_id)
  end
end
