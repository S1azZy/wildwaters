import type { ReactNode } from "react"

import type { FieldCopy } from "./authTypes"

interface AuthFormIntroProps {
  heading: string
  supporting: string
}

export function AuthFormIntro({ heading, supporting }: AuthFormIntroProps) {
  return (
    <div className="auth-form__intro">
      <h2 className="auth-form__heading">{heading}</h2>
      <p className="auth-form__supporting">{supporting}</p>
    </div>
  )
}

interface AuthTextFieldProps {
  autoComplete?: string
  copy: FieldCopy
  name: string
  onChange: (value: string) => void
  secondaryAction?: ReactNode
  required?: boolean
  type?: string
  value: string
}

export function AuthTextField({
  autoComplete,
  copy,
  name,
  onChange,
  secondaryAction,
  required = true,
  type = "text",
  value,
}: AuthTextFieldProps) {
  const inputId = name.replace(/\W+/g, "-")

  return (
    <div className="block space-y-2">
      <div className="flex items-center justify-between gap-4">
        <label className="auth-form__label" htmlFor={inputId}>
          {copy.label}
        </label>
        {secondaryAction}
      </div>
      <input
        autoComplete={autoComplete}
        className="auth-form__input"
        id={inputId}
        name={name}
        onChange={(event) => onChange(event.target.value)}
        placeholder={copy.placeholder}
        required={required}
        type={type}
        value={value}
      />
    </div>
  )
}

export function AuthPasswordField(props: Omit<AuthTextFieldProps, "type">) {
  return <AuthTextField {...props} type="password" />
}

interface AuthSelectFieldProps {
  copy: FieldCopy
  name: string
  onChange: (value: string) => void
  options: Array<{ label: string; value: string }>
  supporting?: string
  value: string
}

export function AuthSelectField({
  copy,
  name,
  onChange,
  options,
  supporting,
  value,
}: AuthSelectFieldProps) {
  const inputId = name.replace(/\W+/g, "-")

  return (
    <label className="block space-y-2" htmlFor={inputId}>
      <span className="auth-form__label">{copy.label}</span>
      <select
        className="auth-form__select"
        id={inputId}
        name={name}
        onChange={(event) => onChange(event.target.value)}
        value={value}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {supporting ? (
        <span className="auth-form__supporting">{supporting}</span>
      ) : null}
    </label>
  )
}

interface AuthFormErrorProps {
  message: string | null
}

export function AuthFormError({ message }: AuthFormErrorProps) {
  if (!message) {
    return null
  }

  return (
    <p className="auth-form__error" role="alert">
      {message}
    </p>
  )
}

interface AuthSubmitProps {
  children: ReactNode
  disabled?: boolean
}

export function AuthSubmit({ children, disabled }: AuthSubmitProps) {
  return (
    <button className="auth-form__submit" disabled={disabled} type="submit">
      {children}
    </button>
  )
}
