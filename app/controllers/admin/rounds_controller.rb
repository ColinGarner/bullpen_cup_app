class Admin::RoundsController < Admin::BaseController
  before_action :set_tournament
  before_action :set_round, only: [ :show, :edit, :update, :destroy, :start, :complete, :cancel ]

  def index
    @rounds = @tournament.rounds.by_round_number.includes(:tournament)
  end

  def show
    # Load matches with proper associations for team access through tournament
    @round = @tournament.rounds.includes(
      matches: [
        { round: { tournament: [:team_a, :team_b] } },
        :match_players,
        :players
      ]
    ).find(params[:id])
  end

  def new
    @round = @tournament.rounds.build
    @round.round_number = @tournament.next_round_number
  end

  def create
    @round = @tournament.rounds.build(round_params)

    if @round.save
      redirect_to scoped_admin_tournament_path(@tournament),
                  notice: "Round was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @round.update(round_params)
      redirect_to scoped_admin_tournament_round_path(@tournament, @round),
                  notice: "Round was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @round.destroy
    redirect_to scoped_admin_tournament_path(@tournament),
                notice: "Round was successfully deleted."
  end

  def start
    if @round.start!
      redirect_to scoped_admin_tournament_round_path(@tournament, @round),
                  notice: "Round has been started."
    else
      redirect_to scoped_admin_tournament_round_path(@tournament, @round),
                  alert: "Could not start the round."
    end
  end

  def complete
    if @round.complete!
      redirect_to scoped_admin_tournament_round_path(@tournament, @round),
                  notice: "Round has been completed."
    else
      redirect_to scoped_admin_tournament_round_path(@tournament, @round),
                  alert: "Could not complete the round."
    end
  end

  def cancel
    if @round.cancel!
      redirect_to scoped_admin_tournament_round_path(@tournament, @round),
                  notice: "Round has been cancelled."
    else
      redirect_to scoped_admin_tournament_round_path(@tournament, @round),
                  alert: "Could not cancel the round."
    end
  end

  private

  def set_tournament
    @tournament = current_group.tournaments.find(params[:tournament_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to scoped_admin_tournaments_path,
                alert: "Tournament not found in #{current_group.name}."
  end

  def set_round
    @round = @tournament.rounds.find(params[:id])
  end

  def round_params
    params.require(:round).permit(:round_number, :name, :date, :description, :status)
  end
end
