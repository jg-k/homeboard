Rails.application.config.mission_control.jobs.http_basic_auth_enabled = false

Rails.application.config.after_initialize do
  MissionControl::Jobs.http_basic_auth_enabled = false
end
