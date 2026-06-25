import type { ReactNode } from "react"

import {
  FeedbackMessage,
  SelectField,
  SubmitButton,
  TextField,
} from "../components/ww"
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
    <TextField
      autoComplete={autoComplete}
      id={inputId}
      label={copy.label}
      name={name}
      onChange={(event) => onChange(event.target.value)}
      placeholder={copy.placeholder}
      required={required}
      secondaryAction={secondaryAction}
      type={type}
      value={value}
    />
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
    <SelectField
      description={supporting}
      id={inputId}
      label={copy.label}
      name={name}
      onValueChange={onChange}
      options={options}
      value={value}
    />
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
    <FeedbackMessage
      className="auth-form__error"
      message={message}
      tone="alert"
    />
  )
}

interface AuthSubmitProps {
  children: ReactNode
  disabled?: boolean
}

export function AuthSubmit({ children, disabled }: AuthSubmitProps) {
  return (
    <SubmitButton
      className="auth-form__submit"
      isPending={disabled}
      type="submit"
    >
      {children}
    </SubmitButton>
  )
}
