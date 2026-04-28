class GradingSystemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_grading_system, only: %i[show edit update destroy set_as_default]

  def show
  end

  def new
    @grading_system = current_user.grading_systems.build
  end

  def edit
  end

  def create
    @grading_system = current_user.grading_systems.build(grading_system_params)
    @grading_system.system_type = "custom"

    if @grading_system.save
      redirect_to settings_path, notice: "Grading system was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @grading_system.update(grading_system_params)
      redirect_to settings_path, notice: "Grading system was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @grading_system.destroy
    redirect_to settings_path, notice: "Grading system was successfully deleted.", status: :see_other
  end

  def set_as_default
    current_user.update(default_grading_system: @grading_system)
    redirect_to settings_path, notice: "#{@grading_system.name} is now your default grading system."
  end

  private

  def set_grading_system
    @grading_system = GradingSystem.for_user(current_user).find(params[:id])
  end

  def grading_system_params
    params.require(:grading_system).permit(:name, :grades)
  end
end
