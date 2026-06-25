import type { ComponentProps, ReactNode } from "react"

import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { cn } from "@/lib/utils"

interface FieldShellProps {
  description?: string
  error?: string | null
  hideLabel?: boolean
  id: string
  label: string
  secondaryAction?: ReactNode
}

type TextFieldProps = Omit<ComponentProps<typeof Input>, "id"> & FieldShellProps

export function TextField({
  className,
  description,
  error,
  hideLabel = false,
  label,
  secondaryAction,
  ...props
}: TextFieldProps) {
  const descriptionId = description ? `${props.id}-description` : undefined
  const errorId = error ? `${props.id}-error` : undefined

  return (
    <Field data-invalid={error ? true : undefined}>
      <div className="flex items-center justify-between gap-4">
        <FieldLabel
          className={hideLabel ? "sr-only" : undefined}
          htmlFor={props.id}
        >
          {label}
        </FieldLabel>
        {secondaryAction}
      </div>
      <Input
        aria-describedby={cn(descriptionId, errorId) || undefined}
        aria-invalid={error ? true : undefined}
        className={className}
        {...props}
      />
      {description ? (
        <FieldDescription id={descriptionId}>{description}</FieldDescription>
      ) : null}
      <FieldError id={errorId}>{error}</FieldError>
    </Field>
  )
}

type TextAreaFieldProps = Omit<ComponentProps<typeof Textarea>, "id"> &
  FieldShellProps

export function TextAreaField({
  className,
  description,
  error,
  hideLabel = false,
  label,
  secondaryAction,
  ...props
}: TextAreaFieldProps) {
  const descriptionId = description ? `${props.id}-description` : undefined
  const errorId = error ? `${props.id}-error` : undefined

  return (
    <Field data-invalid={error ? true : undefined}>
      <div className="flex items-center justify-between gap-4">
        <FieldLabel
          className={hideLabel ? "sr-only" : undefined}
          htmlFor={props.id}
        >
          {label}
        </FieldLabel>
        {secondaryAction}
      </div>
      <Textarea
        aria-describedby={cn(descriptionId, errorId) || undefined}
        aria-invalid={error ? true : undefined}
        className={className}
        {...props}
      />
      {description ? (
        <FieldDescription id={descriptionId}>{description}</FieldDescription>
      ) : null}
      <FieldError id={errorId}>{error}</FieldError>
    </Field>
  )
}

export interface SelectFieldOption {
  label: string
  value: string
}

interface SelectFieldProps extends FieldShellProps {
  name: string
  onValueChange: (value: string) => void
  options: SelectFieldOption[]
  placeholder?: string
  triggerClassName?: string
  value: string
}

export function SelectField({
  description,
  error,
  hideLabel = false,
  id,
  label,
  name,
  onValueChange,
  options,
  placeholder,
  triggerClassName,
  value,
}: SelectFieldProps) {
  const descriptionId = description ? `${id}-description` : undefined
  const errorId = error ? `${id}-error` : undefined

  return (
    <Field data-invalid={error ? true : undefined}>
      <FieldLabel className={hideLabel ? "sr-only" : undefined} htmlFor={id}>
        {label}
      </FieldLabel>
      <Select name={name} onValueChange={onValueChange} value={value}>
        <SelectTrigger
          aria-describedby={cn(descriptionId, errorId) || undefined}
          aria-invalid={error ? true : undefined}
          className={triggerClassName}
          id={id}
        >
          <SelectValue placeholder={placeholder} />
        </SelectTrigger>
        <SelectContent>
          <SelectGroup>
            {options.map((option) => (
              <SelectItem key={option.value} value={option.value}>
                {option.label}
              </SelectItem>
            ))}
          </SelectGroup>
        </SelectContent>
      </Select>
      {description ? (
        <FieldDescription id={descriptionId}>{description}</FieldDescription>
      ) : null}
      <FieldError id={errorId}>{error}</FieldError>
    </Field>
  )
}

export { FieldGroup }
