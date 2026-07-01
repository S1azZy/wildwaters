export interface ShellProps {
  authenticated: boolean
  labels: {
    brandName: string
    brandTagline: string
    explore: string
    primaryMobileNavigation: string
    primaryNavigation: string
    accountMenu: string
    admin: string
    mainPage: string
    profile: string
    signOut: string
    signIn: string
  }
  urls: {
    admin?: string
    dashboard: string
    explore: string
    signIn: string
    signOut: string
  }
}

export interface InertiaFlash {
  alert?: string
  notice?: string
}

export interface SharedPageProps extends Record<string, unknown> {
  shell: ShellProps
}

declare module "@inertiajs/core" {
  export interface InertiaConfig {
    flashDataType: InertiaFlash
    sharedPageProps: SharedPageProps
  }
}
