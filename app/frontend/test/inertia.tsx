import { App } from "@inertiajs/react"
import type { Page, PageProps } from "@inertiajs/core"
import { render } from "@testing-library/react"
import type { ComponentType } from "react"

type FlashData = Page["flash"]

export function renderInertiaPage<Props extends PageProps>(
  Component: ComponentType<Props>,
  props: Props,
  flash: FlashData = {},
) {
  const page: Page<Props> = {
    component: "Test/Page",
    props: {
      ...props,
      errors: {},
    },
    url: "/test",
    version: null,
    rescuedProps: [],
    flash,
    rememberedState: {},
  }

  return render(
    <App
      initialComponent={Component}
      initialPage={page}
      resolveComponent={() => Component}
    />,
  )
}
