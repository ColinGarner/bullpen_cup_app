class Admin::TournamentsController < Admin::BaseController
  before_action :set_tournament, only: [:show, :edit, :update, :destroy, :start, :complete, :cancel, :confirm_destroy]
  
  def index
    @tournaments = Tournament.includes(:created_by).order(created_at: :desc)
    @tournaments = @tournaments.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @tournaments = @tournaments.where(status: params[:status]) if params[:status].present?
  end
  
  def show
  end
  
  def new
    @tournament = Tournament.new
  end
  
  def create
    @tournament = Tournament.new(tournament_params)
    @tournament.created_by = current_user
    
    if @tournament.save
      redirect_to admin_tournament_path(@tournament), notice: 'Tournament was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @tournament.update(tournament_params)
      redirect_to admin_tournament_path(@tournament), notice: 'Tournament was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm_destroy
    unless @tournament.upcoming?
      redirect_to admin_tournaments_path, alert: "Only upcoming tournaments can be deleted. Tournament has status: #{@tournament.status}."
      return
    end
  end
  
  def destroy
    unless @tournament.upcoming?
      redirect_to admin_tournaments_path, alert: "Only upcoming tournaments can be deleted. Tournament has status: #{@tournament.status}."
      return
    end
    
    # Check if tournament has data and user hasn't confirmed deletion
    if (@tournament.teams.any? || @tournament.rounds.any?) && params[:confirm_data_deletion] != 'true'
      redirect_to confirm_destroy_admin_tournament_path(@tournament)
      return
    end
    
    @tournament.destroy
    redirect_to admin_tournaments_path, notice: 'Tournament and all associated data was successfully deleted.'
  end
  
  # Status actions
  def start
    @tournament.start!
    redirect_to admin_tournament_path(@tournament), notice: 'Tournament has been started!'
  end
  
  def complete
    @tournament.complete!
    redirect_to admin_tournament_path(@tournament), notice: 'Tournament has been completed!'
  end
  
  def cancel
    @tournament.cancel!
    redirect_to admin_tournament_path(@tournament), notice: 'Tournament has been cancelled.'
  end
  
  private
  
  def set_tournament
    @tournament = Tournament.find(params[:id])
  end
  
  def tournament_params
    params.require(:tournament).permit(:name, :description, :start_date, :end_date, :venue)
  end
end 