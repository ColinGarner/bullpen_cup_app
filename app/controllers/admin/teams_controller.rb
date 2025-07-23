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

    # Exclude users who are already on ANY team in this tournament
    users_on_tournament_teams = User.joins(team_memberships: :team)
                                   .where(teams: { tournament: @tournament })
                                   .distinct
                                   .pluck(:id)

    @available_users = current_group.users
                                   .where.not(id: users_on_tournament_teams)
                                   .order(:first_name, :last_name)
  end

  def new
    # Check if tournament already has 2 teams
    if @tournament.at_team_limit?
      redirect_to scoped_admin_tournament_path(@tournament),
                  alert: "Tournament already has the maximum of 2 teams. Cannot create more teams."
      return
    end

    @team = @tournament.teams.build
    @available_captains = current_group.users.order(:first_name, :last_name)
  end

  def create
    # Check if tournament already has 2 teams
    if @tournament.at_team_limit?
      redirect_to scoped_admin_tournament_path(@tournament),
                  alert: "Tournament already has the maximum of 2 teams. Cannot create more teams."
      return
    end

    @team = @tournament.teams.build(team_params)

    if @team.save
      # Ensure all teams are properly assigned
      assign_teams_to_tournament(@tournament)

      # Determine which role this team got
      if @tournament.team_a == @team
        notice_message = "Team was successfully created and assigned as Team A."
      elsif @tournament.team_b == @team
        notice_message = "Team was successfully created and assigned as Team B."
      else
        notice_message = "Team was successfully created."
      end

      redirect_to scoped_admin_tournament_path(@tournament), notice: notice_message
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

    # Check if user is already on a team in this tournament
    existing_team = @tournament.teams.joins(:team_memberships)
                               .where(team_memberships: { user: @user })
                               .first

    if existing_team
      redirect_to scoped_admin_tournament_team_path(@tournament, @team),
                  alert: "#{@user.display_name} is already on team '#{existing_team.name}' in this tournament."
      return
    end

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

  def assign_teams_to_tournament(tournament)
    # Get all teams for this tournament in creation order
    all_teams = tournament.teams.order(:created_at)

    # Assign first team as team_a if not already assigned
    if tournament.team_a.nil? && all_teams.first
      tournament.update!(team_a: all_teams.first)
    end

    # Assign second team as team_b if not already assigned
    if tournament.team_b.nil? && all_teams.second
      tournament.update!(team_b: all_teams.second)
    end

    # Reload to get updated associations
    tournament.reload
  end
end
