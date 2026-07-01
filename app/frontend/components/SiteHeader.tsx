import { Link, usePage } from "@inertiajs/react"
import {
  ChevronDownIcon,
  CircleUserRoundIcon,
  HouseIcon,
  LogOutIcon,
  ShieldIcon,
  UserRoundIcon,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

import type { ShellProps } from "../types/page"

export default function SiteHeader({
  authenticated,
  labels,
  urls,
}: ShellProps) {
  return (
    <header
      className="site-header-surface site-header-surface--compact sticky top-0 z-50"
      data-ui="site-header"
    >
      <div
        className="site-header-frame site-header-frame--compact site-header-frame--relaxed site-header-frame--trimmed mx-auto flex w-full max-w-[120rem] flex-col gap-1 px-4 py-1 sm:px-6 lg:px-8"
        data-ui="site-header-frame"
      >
        <div
          className="site-header-shell site-header-shell--feather"
          data-ui="site-header-desktop-row"
        >
          <a
            className="site-header-brand group"
            data-ui="site-header-brand"
            href={urls.explore}
          >
            <span className="site-header-brand-copy">
              <span className="site-header-brand-name">{labels.brandName}</span>
              <span
                className="site-header-brand-tagline"
                data-ui="site-header-tagline"
              >
                {labels.brandTagline}
              </span>
            </span>
          </a>

          <nav
            aria-label={labels.primaryNavigation}
            className="site-header-primary-nav hidden md:flex"
            data-ui="site-header-primary-nav"
          >
            <Button
              asChild
              className="site-header-nav-link site-header-nav-link--prominent"
              size="sm"
              variant="ghost"
            >
              <a
                data-current="false"
                data-ui="site-header-nav-item"
                href={urls.explore}
              >
                {labels.explore}
              </a>
            </Button>
          </nav>

          <div className="site-header-actions" data-ui="site-header-actions">
            <div
              className={
                authenticated
                  ? "site-header-auth-actions"
                  : "site-header-guest-actions"
              }
              data-ui={
                authenticated
                  ? "site-header-auth-actions"
                  : "site-header-guest-actions"
              }
            >
              {authenticated ? (
                <AccountMenu labels={labels} urls={urls} />
              ) : (
                <Button asChild className="site-header-cta" size="sm">
                  <a href={urls.signIn}>{labels.signIn}</a>
                </Button>
              )}
            </div>
          </div>
        </div>

        <nav
          aria-label={labels.primaryMobileNavigation}
          className="site-header-mobile-nav md:hidden"
          data-ui="site-header-primary-nav"
        >
          <Button
            asChild
            className="site-header-mobile-link"
            size="sm"
            variant="ghost"
          >
            <a
              data-current="false"
              data-ui="site-header-nav-item"
              href={urls.explore}
            >
              {labels.explore}
            </a>
          </Button>
        </nav>
      </div>
    </header>
  )
}

function AccountMenu({ labels, urls }: Pick<ShellProps, "labels" | "urls">) {
  const { url } = usePage()
  const isAdminArea = url.startsWith("/admin")

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          aria-label={labels.accountMenu}
          className="site-header-cta"
          size="sm"
          variant="outline"
        >
          <CircleUserRoundIcon data-icon="inline-start" />
          {labels.accountMenu}
          <ChevronDownIcon data-icon="inline-end" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuGroup>
          <DropdownMenuItem disabled>
            <UserRoundIcon data-icon="inline-start" />
            {labels.profile}
          </DropdownMenuItem>
          {urls.admin && !isAdminArea ? (
            <DropdownMenuItem asChild>
              <a href={urls.admin}>
                <ShieldIcon data-icon="inline-start" />
                {labels.admin}
              </a>
            </DropdownMenuItem>
          ) : null}
          {urls.admin && isAdminArea ? (
            <DropdownMenuItem asChild>
              <a href={urls.explore}>
                <HouseIcon data-icon="inline-start" />
                {labels.mainPage}
              </a>
            </DropdownMenuItem>
          ) : null}
        </DropdownMenuGroup>
        <DropdownMenuSeparator />
        <DropdownMenuGroup>
          <DropdownMenuItem asChild>
            <Link as="button" href={urls.signOut} method="delete" type="button">
              <LogOutIcon data-icon="inline-start" />
              {labels.signOut}
            </Link>
          </DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
