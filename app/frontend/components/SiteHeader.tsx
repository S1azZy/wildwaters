import type { ShellProps } from "../types/page"

export default function SiteHeader({
  authenticated,
  labels,
  urls,
}: ShellProps) {
  const action = authenticated
    ? { label: labels.profile, url: urls.dashboard }
    : { label: labels.signIn, url: urls.signIn }

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
            <a
              className="site-header-nav-link site-header-nav-link--prominent"
              data-current="false"
              data-ui="site-header-nav-item"
              href={urls.explore}
            >
              {labels.explore}
            </a>
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
              <a className="site-header-cta" href={action.url}>
                {action.label}
              </a>
            </div>
          </div>
        </div>

        <nav
          aria-label={labels.primaryMobileNavigation}
          className="site-header-mobile-nav md:hidden"
          data-ui="site-header-primary-nav"
        >
          <a
            className="site-header-mobile-link"
            data-current="false"
            data-ui="site-header-nav-item"
            href={urls.explore}
          >
            {labels.explore}
          </a>
        </nav>
      </div>
    </header>
  )
}
