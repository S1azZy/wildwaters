import { useEffect, useState } from "react"

import type { InertiaFlash } from "../types/page"
import { FeedbackMessage } from "./ww"

const FLASH_DISMISS_MS = 4_500

interface FlashMessageProps {
  message: string
  tone: keyof InertiaFlash
}

function flashMessages({ alert, notice }: InertiaFlash) {
  return [
    { message: notice, tone: "notice" as const },
    { message: alert, tone: "alert" as const },
  ].filter(
    (entry): entry is { message: string; tone: "notice" | "alert" } =>
      typeof entry.message === "string" && entry.message.trim().length > 0,
  )
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
  const [messages, setMessages] = useState(() =>
    flashMessages({ alert, notice }),
  )

  useEffect(() => {
    const nextMessages = flashMessages({ alert, notice })
    setMessages(nextMessages)

    if (nextMessages.length === 0) {
      return undefined
    }

    const timeoutId = window.setTimeout(() => {
      setMessages([])
    }, FLASH_DISMISS_MS)

    return () => window.clearTimeout(timeoutId)
  }, [alert, notice])

  if (messages.length === 0) {
    return null
  }

  return (
    <div
      className="ui-flash-stack"
      data-testid="flash-stack"
      data-ui="flash-stack"
    >
      {messages.map(({ message, tone }) => (
        <FlashMessage key={tone} message={message} tone={tone} />
      ))}
    </div>
  )
}
