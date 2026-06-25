import type { InertiaFlash } from "../types/page"
import { FeedbackMessage } from "./ww"

interface FlashMessageProps {
  message: string
  tone: keyof InertiaFlash
}

function FlashMessage({ message, tone }: FlashMessageProps) {
  return (
    <FeedbackMessage
      className="ui-flash"
      message={message}
      messageDataUi="flash-message"
      rootDataUi="flash"
      tone={tone}
    />
  )
}

export default function Flash({ alert, notice }: InertiaFlash) {
  const messages = [
    { message: notice, tone: "notice" as const },
    { message: alert, tone: "alert" as const },
  ].filter(
    (entry): entry is { message: string; tone: "notice" | "alert" } =>
      typeof entry.message === "string" && entry.message.trim().length > 0,
  )

  if (messages.length === 0) {
    return null
  }

  return (
    <div className="ui-flash-stack mx-auto mb-6 w-full max-w-2xl px-4 sm:px-0">
      {messages.map(({ message, tone }) => (
        <FlashMessage key={tone} message={message} tone={tone} />
      ))}
    </div>
  )
}
