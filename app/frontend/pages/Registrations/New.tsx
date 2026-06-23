import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import AuthLayout from "../authLayout"
import {
  AuthFormError,
  AuthFormIntro,
  AuthSubmit,
  AuthTextField,
} from "../authForm"
import type { AuthPageProps, FieldCopy, LocaleOption } from "../authTypes"

export interface RegistrationNewPageProps extends AuthPageProps {
  copy: {
    cardHeading: string
    cardSupporting: string
    localeHint: string
    submit: string
  }
  fields: {
    email: FieldCopy
    locale: FieldCopy
    password: FieldCopy
    passwordConfirmation: FieldCopy
  }
  formError: string | null
  localeOptions: LocaleOption[]
  urls: {
    submit: string
  }
  values: {
    email: string | null
    locale: string
  }
}

export default function New({
  auth,
  copy,
  fields,
  formError,
  localeOptions,
  shell,
  urls,
  values,
}: RegistrationNewPageProps) {
  const { data, post, processing, setData } = useForm({
    registration: {
      email: values.email ?? "",
      locale: values.locale,
      password: "",
      password_confirmation: "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    post(urls.submit)
  }

  return (
    <AuthLayout auth={auth} page="registration" shell={shell}>
      <form className="space-y-5" onSubmit={submit}>
        <AuthFormIntro
          heading={copy.cardHeading}
          supporting={copy.cardSupporting}
        />
        <AuthFormError message={formError} />

        <AuthTextField
          autoComplete="email"
          copy={fields.email}
          name="registration[email]"
          onChange={(email) =>
            setData("registration", { ...data.registration, email })
          }
          type="email"
          value={data.registration.email}
        />

        <AuthTextField
          autoComplete="new-password"
          copy={fields.password}
          name="registration[password]"
          onChange={(password) =>
            setData("registration", { ...data.registration, password })
          }
          type="password"
          value={data.registration.password}
        />

        <AuthTextField
          autoComplete="new-password"
          copy={fields.passwordConfirmation}
          name="registration[password_confirmation]"
          onChange={(password_confirmation) =>
            setData("registration", {
              ...data.registration,
              password_confirmation,
            })
          }
          type="password"
          value={data.registration.password_confirmation}
        />

        <label className="block space-y-2" htmlFor="registration-locale">
          <span className="auth-form__label">{fields.locale.label}</span>
          <select
            className="auth-form__select"
            id="registration-locale"
            name="registration[locale]"
            onChange={(event) =>
              setData("registration", {
                ...data.registration,
                locale: event.target.value,
              })
            }
            value={data.registration.locale}
          >
            {localeOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <p className="auth-form__supporting">{copy.localeHint}</p>
        </label>

        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </form>
    </AuthLayout>
  )
}
