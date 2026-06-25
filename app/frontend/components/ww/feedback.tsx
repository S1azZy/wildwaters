import { AlertCircleIcon, CheckCircle2Icon } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { cn } from "@/lib/utils"

export type FeedbackTone = "notice" | "alert"

interface FeedbackMessageProps {
  className?: string
  message: string
  messageDataUi?: string
  rootDataUi?: string
  title?: string
  tone: FeedbackTone
}

export function FeedbackMessage({
  className,
  message,
  messageDataUi,
  rootDataUi,
  title,
  tone,
}: FeedbackMessageProps) {
  const isAlert = tone === "alert"
  const Icon = isAlert ? AlertCircleIcon : CheckCircle2Icon

  return (
    <Alert
      aria-atomic="true"
      aria-live={isAlert ? "assertive" : "polite"}
      className={cn("shadow-sm", className)}
      data-tone={tone}
      data-ui={rootDataUi}
      role={isAlert ? "alert" : "status"}
      variant={isAlert ? "destructive" : "default"}
    >
      <Icon aria-hidden="true" />
      {title ? <AlertTitle>{title}</AlertTitle> : null}
      <AlertDescription data-ui={messageDataUi}>{message}</AlertDescription>
    </Alert>
  )
}
