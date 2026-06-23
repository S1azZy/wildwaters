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

export interface SessionNewPageProps extends AuthPageProps {
  copy: {
    cardHeading: string
    cardSupporting: string
    forgotPassword: string
    submit: string
  }
  fields: {
    email: FieldCopy
    password: FieldCopy
  }
  formError: string | null
  urls: {
    forgotPassword: string
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
  formError,
  shell,
  urls,
  values,
}: SessionNewPageProps) {
  const { data, post, processing, setData } = useForm({
    session: {
      email: values.email ?? "",
      password: "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    post(urls.submit)
  }

  return (
    <AuthLayout auth={auth} page="session" shell={shell}>
      <form className="space-y-5" onSubmit={submit}>
        <AuthFormIntro
          heading={copy.cardHeading}
          supporting={copy.cardSupporting}
        />
        <AuthFormError message={formError} />

        <AuthTextField
          autoComplete="email"
          copy={fields.email}
          name="session[email]"
          onChange={(email) => setData("session", { ...data.session, email })}
          type="email"
          value={data.session.email}
        />

        <div className="space-y-2">
          <div className="flex items-center justify-between gap-4">
            <label className="auth-form__label" htmlFor="session-password">
              {fields.password.label}
            </label>
            <a className="auth-form__inline-link" href={urls.forgotPassword}>
              {copy.forgotPassword}
            </a>
          </div>
          <input
            autoComplete="current-password"
            className="auth-form__input"
            id="session-password"
            name="session[password]"
            onChange={(event) =>
              setData("session", {
                ...data.session,
                password: event.target.value,
              })
            }
            placeholder={fields.password.placeholder}
            required
            type="password"
            value={data.session.password}
          />
        </div>

        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </form>
    </AuthLayout>
  )
}
