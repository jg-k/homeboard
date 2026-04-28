class MeasurementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_metric
  before_action :set_measurement, only: %i[edit update destroy]

  def create
    @measurement = @metric.measurements.build(measurement_params)

    if @measurement.save
      redirect_back fallback_location: metrics_path, notice: "Measurement logged."
    else
      redirect_back fallback_location: metrics_path, alert: "Failed to log measurement."
    end
  end

  def edit
  end

  def update
    if @measurement.update(measurement_params)
      redirect_to metric_path(@metric), notice: "Measurement updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @measurement.destroy
    redirect_back fallback_location: metric_path(@metric), notice: "Measurement deleted.", status: :see_other
  end

  private

  def set_metric
    @metric = current_user.metrics.find(params[:metric_id])
  end

  def set_measurement
    @measurement = @metric.measurements.find(params[:id])
  end

  def measurement_params
    params.require(:measurement).permit(:value, :recorded_at, :notes)
  end
end
