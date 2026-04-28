class MetricTargetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_metric

  def create
    @target = @metric.targets.build(target_params)

    if @target.save
      redirect_back fallback_location: metrics_path, notice: "Target set."
    else
      redirect_back fallback_location: metrics_path, alert: "Failed to set target."
    end
  end

  def destroy
    @target = @metric.targets.find(params[:id])
    @target.destroy
    redirect_back fallback_location: metrics_path, notice: "Target deleted.", status: :see_other
  end

  private

  def set_metric
    @metric = current_user.metrics.find(params[:metric_id])
  end

  def target_params
    params.require(:target).permit(:value, :applicable_from)
  end
end
