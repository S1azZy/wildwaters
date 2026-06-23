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
  required?: boolean
  type?: string
  value: string
}

export function AuthTextField({
  autoComplete,
  copy,
  name,
  onChange,
  required = true,
  type = "text",
  value,
}: AuthTextFieldProps) {
  const inputId = name.replace(/\W+/g, "-")

  return (
    <label className="block space-y-2" htmlFor={inputId}>
      <span className="auth-form__label">{copy.label}</span>
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
