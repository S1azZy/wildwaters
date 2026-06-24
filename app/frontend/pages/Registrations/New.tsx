import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import AuthLayout from "../authLayout"
import {
  AuthFormError,
  AuthFormIntro,
  AuthPasswordField,
  AuthSelectField,
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

        <AuthPasswordField
          autoComplete="new-password"
          copy={fields.password}
          name="registration[password]"
          onChange={(password) =>
            setData("registration", { ...data.registration, password })
          }
          value={data.registration.password}
        />

        <AuthPasswordField
          autoComplete="new-password"
          copy={fields.passwordConfirmation}
          name="registration[password_confirmation]"
          onChange={(password_confirmation) =>
            setData("registration", {
              ...data.registration,
              password_confirmation,
            })
          }
          value={data.registration.password_confirmation}
        />

        <AuthSelectField
          copy={fields.locale}
          name="registration[locale]"
          onChange={(locale) =>
            setData("registration", {
              ...data.registration,
              locale,
            })
          }
          options={localeOptions}
          supporting={copy.localeHint}
          value={data.registration.locale}
        />

        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </form>
    </AuthLayout>
  )
}
