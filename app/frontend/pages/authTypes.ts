import type { AuthShellProps } from "../components/AuthShell"
import type { SharedPageProps } from "../types/page"

export interface FieldCopy {
  label: string
  placeholder?: string
}

export interface LocaleOption {
  label: string
  value: string
}

export interface AuthPageProps extends SharedPageProps {
  auth: AuthShellProps
}
