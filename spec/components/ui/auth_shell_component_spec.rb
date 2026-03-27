require "rails_helper"

RSpec.describe Ui::AuthShellComponent, type: :component do
  def component_attributes(overrides = {})
    {
      variant: :session,
      eyebrow: "Welcome back",
      title: "Sign in",
      description: "Return to your saved map.",
      alternate_prompt: "Need an account?",
      alternate_label: "Sign up",
      alternate_path: "/registration/new"
    }.merge(overrides)
  end

  def render_component(overrides = {}, &)
    render_inline(described_class.new(**component_attributes(overrides)), &)
  end

  def recovery_component
    described_class.new(
      **component_attributes(
        variant: :recovery,
        eyebrow: "Account recovery",
        title: "Reset your password",
        description: "We'll send you a reset link.",
        alternate_prompt: "Remembered it?",
        alternate_label: "Back to sign in",
        alternate_path: "/session/new"
      )
    )
  end

  it "renders the shared auth shell with panel content and alternate action", :aggregate_failures do
    render_component do |shell|
      shell.with_panel do
        '<div class="panel-body">Panel body</div>'.html_safe
      end
    end

    expect(page).to have_css("[data-ui='auth-shell'][data-variant='session']")
    expect(page).to have_css("[data-ui='auth-card']", text: "Basecamp access")
    expect(page).to have_css(".panel-body", text: "Panel body")
    expect(page).to have_link("Sign up", href: "/registration/new")
    expect(page).not_to have_css("[data-ui='auth-footer']")
  end

  it "supports the recovery variant label" do
    component = recovery_component

    expect(component.panel_label).to eq("Secure account recovery")
    expect(component.shell_class).to include("auth-shell--recovery")
  end
end
