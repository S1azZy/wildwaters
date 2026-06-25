import type { ComponentProps, ReactNode } from "react"

import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip"
import { cn } from "@/lib/utils"

type ButtonProps = ComponentProps<typeof Button>

interface SubmitButtonProps extends ButtonProps {
  isPending?: boolean
  pendingLabel?: ReactNode
}

export function SubmitButton({
  children,
  className,
  disabled,
  isPending = false,
  pendingLabel,
  ...props
}: SubmitButtonProps) {
  return (
    <Button
      aria-busy={isPending || undefined}
      className={cn("w-full", className)}
      disabled={disabled || isPending}
      type="submit"
      {...props}
    >
      {isPending ? <Spinner data-icon="inline-start" /> : null}
      {isPending && pendingLabel ? pendingLabel : children}
    </Button>
  )
}

interface IconControlButtonProps extends Omit<ButtonProps, "children"> {
  children: ReactNode
  label: string
  tooltip?: string
}

export function IconControlButton({
  children,
  className,
  label,
  tooltip,
  variant = "outline",
  ...props
}: IconControlButtonProps) {
  const button = (
    <Button
      aria-label={label}
      className={cn("rounded-full", className)}
      size="icon"
      variant={variant}
      {...props}
    >
      {children}
    </Button>
  )

  if (!tooltip) {
    return button
  }

  return (
    <Tooltip>
      <TooltipTrigger asChild>{button}</TooltipTrigger>
      <TooltipContent>{tooltip}</TooltipContent>
    </Tooltip>
  )
}
