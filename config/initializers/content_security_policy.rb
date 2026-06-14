# Be sure to restart your server when you modify this file.

require "securerandom"

Rails.application.configure do
  config.content_security_policy do |policy|
    vite_websocket_sources = Rails.env.development? ? [ "ws://localhost:3036", "ws://127.0.0.1:3036" ] : []

    policy.default_src :self
    policy.base_uri :self
    policy.child_src :blob
    policy.connect_src :self, "https://tiles.openfreemap.org", "https://tiles.stadiamaps.com",
                       *vite_websocket_sources
    policy.font_src :self, :data, "https://fonts.gstatic.com", "https://tiles.openfreemap.org", "https://tiles.stadiamaps.com"
    policy.form_action :self
    policy.frame_ancestors :none
    policy.img_src :self, :data, :blob, "https://tiles.openfreemap.org", "https://tiles.stadiamaps.com"
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.style_src_attr :unsafe_inline
    policy.worker_src :self, :blob
  end

  # Rails importmap emits inline bootstrap tags, so use a real per-request nonce.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
  config.content_security_policy_nonce_auto = true
end
