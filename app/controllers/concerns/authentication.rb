module Authentication
  extend ActiveSupport::Concern

  SESSION_COOKIE_KEY = :session_token

  included do
    before_action :resume_session
    helper_method :authenticated?, :current_session, :current_user
  end

  private

  def authenticated?
    current_user.present?
  end

  def current_session
    Current.session
  end

  def current_user
    Current.user
  end

  def require_authentication
    return if authenticated?

    redirect_to new_session_path, alert: t("auth.sessions.require_authentication")
  end

  def start_session!(session_record, token)
    cookies.signed[SESSION_COOKIE_KEY] = {
      value: token,
      expires: session_record.expires_at,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }

    Current.session = session_record
    Current.user = session_record.user
  end

  def clear_current_session!
    Current.reset
    cookies.delete(SESSION_COOKIE_KEY)
  end

  def issue_session_for!(user, user_identity)
    result = Auth::IssueSession.call(
      input: {
        user:,
        user_identity:,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )

    session_record, token = result.value!.values_at(:session, :token)
    start_session!(session_record, token)
  end

  def resume_session
    Current.reset

    token = cookies.signed[SESSION_COOKIE_KEY]
    return if token.blank?

    session_record = Session.active.find_by_token(token)

    if session_record.present?
      Current.session = session_record
      Current.user = session_record.user
      session_record.update_column(:last_seen_at, Time.current)
    else
      cookies.delete(SESSION_COOKIE_KEY)
    end
  end
end
