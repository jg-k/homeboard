# theCrag stopped serving logbooks anonymously, so syncing needs a session
# cookie from a signed-in browser. Rather than ask five climbers each to supply
# one, an admin pastes theirs here and it is used to fetch for everyone.
class Admin::ThecragController < Admin::BaseController
  def show
    @cookie_present = current_user.thecrag_session_cookie.present?
    @climbers = User.where.not(thecrag_username: [ nil, "" ]).order(:thecrag_username)
  end

  def update
    current_user.update!(thecrag_session_cookie: params[:thecrag_session_cookie].to_s.strip.presence)
    redirect_to admin_thecrag_path, notice: "Session cookie saved."
  end

  def sync
    cookie = current_user.thecrag_session_cookie
    return redirect_to admin_thecrag_path, alert: "Paste a session cookie first." if cookie.blank?

    targets = User.where.not(thecrag_username: [ nil, "" ])
    targets = targets.where(id: params[:user_id]) if params[:user_id].present?

    if targets.empty?
      return redirect_to admin_thecrag_path, alert: "Nobody has a theCrag username set."
    end

    targets.each { |user| ThecragSyncJob.perform_later(user.id, user.thecrag_username, cookie) }
    redirect_to admin_thecrag_path,
                notice: "Syncing #{targets.count} climber#{'s' if targets.count != 1} from theCrag."
  end
end
