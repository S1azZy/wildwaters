import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import AuthLayout from "../authLayout"
import {
  AuthFormError,
  AuthFormIntro,
  AuthSubmit,
  AuthTextField,
} from "../authForm"
import type { AuthPageProps, FieldCopy } from "../authTypes"

export interface PasswordResetEditPageProps extends AuthPageProps {
  copy: {
    cardHeading: string
    cardSupporting: string
    submit: string
  }
  fields: {
    password: FieldCopy
    passwordConfirmation: FieldCopy
  }
  formError: string | null
  urls: {
    submit: string
  }
}

export default function Edit({
  auth,
  copy,
  fields,
  formError,
  shell,
  urls,
}: PasswordResetEditPageProps) {
  const { data, patch, processing, setData } = useForm({
    password_reset: {
      password: "",
      password_confirmation: "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    patch(urls.submit)
  }

  return (
    <AuthLayout auth={auth} page="password-reset-edit" shell={shell}>
      <form className="space-y-5" onSubmit={submit}>
        <AuthFormIntro
          heading={copy.cardHeading}
          supporting={copy.cardSupporting}
        />
        <AuthFormError message={formError} />

        <AuthTextField
          autoComplete="new-password"
          copy={fields.password}
          name="password_reset[password]"
          onChange={(password) =>
            setData("password_reset", { ...data.password_reset, password })
          }
          type="password"
          value={data.password_reset.password}
        />

        <AuthTextField
          autoComplete="new-password"
          copy={fields.passwordConfirmation}
          name="password_reset[password_confirmation]"
          onChange={(password_confirmation) =>
            setData("password_reset", {
              ...data.password_reset,
              password_confirmation,
            })
          }
          type="password"
          value={data.password_reset.password_confirmation}
        />

        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </form>
    </AuthLayout>
  )
}
