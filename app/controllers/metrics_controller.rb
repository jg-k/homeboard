class MetricsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_metric, only: %i[show edit update destroy]

  def index
    @metrics = current_user.metrics.order(:name)
  end

  def new
    @metric = current_user.metrics.build
  end

  def show
    @chart_data = @metric.chart_data_with_targets
    @measurements = @metric.measurements.order(recorded_at: :desc).limit(20)
  end

  def edit
  end

  def create
    @metric = current_user.metrics.build(metric_params)

    if @metric.save
      create_initial_target if params[:metric][:initial_target].present?
      redirect_to metrics_path, notice: "Metric was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @metric.update(metric_params)
      redirect_to metrics_path, notice: "Metric was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @metric.destroy
    redirect_to metrics_path, notice: "Metric was successfully deleted.", status: :see_other
  end

  private

  def set_metric
    @metric = current_user.metrics.find(params[:id])
  end

  def metric_params
    params.require(:metric).permit(:name, :unit, :initial_target)
  end

  def create_initial_target
    @metric.targets.create(
      value: params[:metric][:initial_target],
      applicable_from: Time.current
    )
  end
end
