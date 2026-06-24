export interface ShellProps {
  authenticated: boolean
  labels: {
    brandName: string
    brandTagline: string
    explore: string
    primaryMobileNavigation: string
    primaryNavigation: string
    profile: string
    signIn: string
  }
  urls: {
    dashboard: string
    explore: string
    signIn: string
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
