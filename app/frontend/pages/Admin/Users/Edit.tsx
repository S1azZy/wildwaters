import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import { FieldGroup, SelectField, TextField } from "@/components/ww"

import type { SharedPageProps } from "../../../types/page"
import AdminLayout, { type AdminNavigationSection } from "../AdminLayout"

interface FieldCopy {
  label: string
  placeholder?: string
}

interface Option {
  label: string
  value: string
}

export interface AdminUsersEditPageProps extends SharedPageProps {
  copy: {
    title: string
    heading: string
    description: string
    toolbarLabel: string
    back: string
    detailsHeading: string
    formHeading: string
    submit: string
    fields: {
      displayName: FieldCopy
      role: FieldCopy
      status: FieldCopy
    }
    details: {
      email: string
      locale: string
      createdAt: string
      updatedAt: string
    }
  }
  navigation: {
    sections: AdminNavigationSection[]
  }
  options: {
    roles: Option[]
    statuses: Option[]
  }
  errors?: Record<string, string>
  urls: {
    index: string
    update: string
  }
  user: {
    id: string
    displayName: string | null
    email: string
    locale: string
    role: string
    status: string
    createdAt: string
    updatedAt: string
  }
}

export default function Edit({
  copy,
  errors = {},
  navigation,
  options,
  shell,
  urls,
  user,
}: AdminUsersEditPageProps) {
  const { data, patch, processing, setData } = useForm({
    user: {
      display_name: user.displayName ?? "",
      role: user.role,
      status: user.status,
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    patch(urls.update)
  }

  return (
    <AdminLayout
      description={copy.description}
      heading={copy.heading}
      navigation={navigation}
      shell={shell}
      title={copy.title}
      toolbarLabel={copy.toolbarLabel}
    >
      <Button asChild className="w-fit" variant="ghost">
        <a href={urls.index}>{copy.back}</a>
      </Button>

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(20rem,0.65fr)]">
        <Card className="rounded-lg">
          <CardHeader>
            <h2 className="font-heading text-base leading-snug font-medium">
              {copy.formHeading}
            </h2>
            <CardDescription>{copy.description}</CardDescription>
          </CardHeader>
          <CardContent>
            <form className="flex flex-col gap-5" onSubmit={submit}>
              <FieldGroup>
                <TextField
                  id="admin-user-display-name"
                  label={copy.fields.displayName.label}
                  name="user[display_name]"
                  onChange={(event) =>
                    setData("user", {
                      ...data.user,
                      display_name: event.currentTarget.value,
                    })
                  }
                  placeholder={copy.fields.displayName.placeholder}
                  value={data.user.display_name}
                />
                <SelectField
                  id="admin-user-role"
                  label={copy.fields.role.label}
                  name="user[role]"
                  onValueChange={(role) =>
                    setData("user", { ...data.user, role })
                  }
                  options={options.roles}
                  value={data.user.role}
                />
                <SelectField
                  id="admin-user-status"
                  label={copy.fields.status.label}
                  name="user[status]"
                  onValueChange={(status) =>
                    setData("user", { ...data.user, status })
                  }
                  options={options.statuses}
                  value={data.user.status}
                />
              </FieldGroup>

              {Object.keys(errors).length > 0 ? (
                <p className="text-sm text-destructive" role="alert">
                  {Object.values(errors).join(" ")}
                </p>
              ) : null}

              <Button className="w-fit" disabled={processing} type="submit">
                {copy.submit}
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card className="rounded-lg">
          <CardHeader>
            <h2 className="font-heading text-base leading-snug font-medium">
              {copy.detailsHeading}
            </h2>
          </CardHeader>
          <CardContent>
            <dl className="grid gap-4 text-sm">
              <Detail label={copy.details.email} value={user.email} />
              <Detail label={copy.details.locale} value={user.locale} />
              <Detail label={copy.details.createdAt} value={user.createdAt} />
              <Detail label={copy.details.updatedAt} value={user.updatedAt} />
            </dl>
          </CardContent>
        </Card>
      </div>
    </AdminLayout>
  )
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div className="grid gap-1">
      <dt className="text-xs font-medium uppercase text-muted-foreground">
        {label}
      </dt>
      <dd className="break-words text-foreground">{value}</dd>
    </div>
  )
}
