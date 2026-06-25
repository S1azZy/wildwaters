import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import AuthLayout from "../authLayout"
import { AuthFormIntro, AuthSubmit, AuthTextField } from "../authForm"
import type { AuthPageProps, FieldCopy } from "../authTypes"

export interface PasswordResetNewPageProps extends AuthPageProps {
  copy: {
    cardHeading: string
    cardSupporting: string
    submit: string
  }
  fields: {
    email: FieldCopy
  }
  urls: {
    submit: string
  }
  values: {
    email: string | null
  }
}

export default function New({
  auth,
  copy,
  fields,
  shell,
  urls,
  values,
}: PasswordResetNewPageProps) {
  const { data, post, processing, setData } = useForm({
    password_reset: {
      email: values.email ?? "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    post(urls.submit)
  }

  return (
    <AuthLayout auth={auth} page="password-reset-new" shell={shell}>
      <form className="flex flex-col gap-5" onSubmit={submit}>
        <AuthFormIntro
          heading={copy.cardHeading}
          supporting={copy.cardSupporting}
        />

        <AuthTextField
          autoComplete="email"
          copy={fields.email}
          name="password_reset[email]"
          onChange={(email) =>
            setData("password_reset", { ...data.password_reset, email })
          }
          type="email"
          value={data.password_reset.email}
        />

        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </form>
    </AuthLayout>
  )
}
