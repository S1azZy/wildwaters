import type { AuthShellProps } from "../../components/AuthShell"
import type { ShellProps } from "../../types/page"

export const guestShell: ShellProps = {
  authenticated: false,
  labels: {
    brandName: "Wild Waters",
    brandTagline: "Swim the World",
    explore: "Explore",
    profile: "Profile",
    signIn: "Log in",
  },
  urls: {
    dashboard: "/dashboard",
    explore: "/",
    signIn: "/session/new",
  },
}

export const sessionAuth: AuthShellProps = {
  variant: "session",
  eyebrow: "Welcome back",
  title: "Sign in",
  description: "Return to your saved waterfalls.",
  panelLabel: "Basecamp access",
  alternatePrompt: "Don't have an account?",
  alternateLabel: "Sign up",
  alternateUrl: "/registration/new",
}

export const registrationAuth: AuthShellProps = {
  variant: "registration",
  eyebrow: "New account",
  title: "Create your account",
  description: "Set up your basecamp.",
  panelLabel: "Field kit setup",
  alternatePrompt: "Already have an account?",
  alternateLabel: "Sign in",
  alternateUrl: "/session/new",
}

export const recoveryAuth: AuthShellProps = {
  variant: "recovery",
  eyebrow: "Account recovery",
  title: "Reset your password",
  description: "We'll email you a one-time link.",
  panelLabel: "Secure account recovery",
  alternatePrompt: "Remembered it?",
  alternateLabel: "Back to sign in",
  alternateUrl: "/session/new",
}
