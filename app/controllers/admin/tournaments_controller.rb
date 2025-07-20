class Admin::TournamentsController < Admin::BaseController
  before_action :set_tournament, only: [ :show, :edit, :update, :destroy, :confirm_destroy ]

  def index
    @tournaments = current_group.tournaments.by_start_date.includes(:created_by, :teams, :rounds)
  end

  def show
    @teams = @tournament.teams.includes(:players, :captain)
    @rounds = @tournament.rounds.includes(:matches)
  end

  def new
    @tournament = current_group.tournaments.build
  end

  def create
    @tournament = current_group.tournaments.build(tournament_params)
    @tournament.created_by = current_user

    if @tournament.save
      redirect_to admin_tournament_path(group_slug: current_group.slug, id: @tournament), notice: "Tournament was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tournament.update(tournament_params)
      redirect_to admin_tournament_path(group_slug: current_group.slug, id: @tournament), notice: "Tournament was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm_destroy
    # Confirmation view
  end

  def destroy
    @tournament.destroy
    redirect_to admin_tournaments_path(group_slug: current_group.slug), notice: "Tournament was successfully deleted."
  end

  private

  def set_tournament
    @tournament = current_group.tournaments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_tournaments_path(group_slug: current_group.slug), alert: "Tournament not found in #{current_group.name}."
  end

  def tournament_params
    params.require(:tournament).permit(:name, :description, :start_date, :end_date, :venue)
  end
end
