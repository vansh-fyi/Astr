"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { DOCS_GROUP, DOCS_LINKS } from "@/lib/docs-nav";
import { AstrMark, Wordmark } from "./brand";

function DocumentationNav({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  return (
    <nav aria-label="Documentation">
      <div className="docs-nav-group">
        <h2>{DOCS_GROUP}</h2>
        {DOCS_LINKS.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            aria-current={pathname === link.href ? "page" : undefined}
            onClick={onNavigate}
          >
            {link.label}
          </Link>
        ))}
      </div>
    </nav>
  );
}

export function DocsShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const searchDialog = useRef<HTMLDialogElement>(null);
  const mobileDialog = useRef<HTMLDialogElement>(null);
  const [query, setQuery] = useState("");
  const results = DOCS_LINKS.filter((link) =>
    `${link.label} ${DOCS_GROUP}`
      .toLowerCase()
      .includes(query.trim().toLowerCase()),
  );

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        if (searchDialog.current?.open) searchDialog.current.close();
        else searchDialog.current?.showModal();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  // Close any open dialog once navigation completes.
  useEffect(() => {
    searchDialog.current?.close();
    mobileDialog.current?.close();
  }, [pathname]);

  return (
    <div className="docs-root">
      <a className="docs-skip" href="#documentation-content">
        Skip to content
      </a>
      <header className="docs-header">
        <div className="docs-header-inner">
          <button
            type="button"
            className="docs-mobile-trigger"
            aria-label="Open navigation"
            onClick={() => mobileDialog.current?.showModal()}
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.25"
              aria-hidden="true"
            >
              <path d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <Link className="docs-logo" href="/">
            <span className="docs-logo-mark">
              <AstrMark size={19} />
            </span>
            <Wordmark />
          </Link>
          <nav className="docs-header-nav" aria-label="Main navigation">
            {DOCS_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                aria-current={pathname === link.href ? "page" : undefined}
              >
                {link.label}
              </Link>
            ))}
          </nav>
          <button
            type="button"
            className="docs-search-trigger"
            onClick={() => searchDialog.current?.showModal()}
            aria-label="Search the colour system"
          >
            <svg
              width="15"
              height="15"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.25"
              aria-hidden="true"
            >
              <circle cx="10.5" cy="10.5" r="6.5" />
              <path d="m16 16 5 5" />
            </svg>
            <span>Search the colour system…</span>
            <kbd>⌘ K</kbd>
          </button>
        </div>
      </header>
      <div className="docs-workspace">
        <aside className="docs-sidebar">
          <DocumentationNav />
        </aside>
        <main
          id="documentation-content"
          key={pathname}
          className="docs-content"
          tabIndex={-1}
        >
          {children}
        </main>
      </div>
      <dialog
        ref={searchDialog}
        className="docs-dialog"
        aria-label="Search the colour system"
        onClick={(event) => {
          if (event.target === event.currentTarget)
            searchDialog.current?.close();
        }}
      >
        <div className="docs-search-field">
          <input
            autoFocus
            aria-label="Search pages"
            placeholder="Search the colour system…"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
          <button
            type="button"
            className="docs-dialog-close"
            onClick={() => searchDialog.current?.close()}
            aria-label="Close search"
          >
            Esc
          </button>
        </div>
        <div className="docs-search-results">
          {results.length ? (
            results.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => {
                  searchDialog.current?.close();
                  setQuery("");
                }}
              >
                <span>{link.label}</span>
                <small>{DOCS_GROUP}</small>
              </Link>
            ))
          ) : (
            <p>No pages found for “{query}”. Try a page name.</p>
          )}
        </div>
      </dialog>
      <dialog
        ref={mobileDialog}
        className="docs-dialog docs-mobile-dialog"
        aria-label="Documentation navigation"
        onClick={(event) => {
          if (event.target === event.currentTarget)
            mobileDialog.current?.close();
        }}
      >
        <button
          type="button"
          className="docs-dialog-close"
          onClick={() => mobileDialog.current?.close()}
        >
          Close
        </button>
        <DocumentationNav onNavigate={() => mobileDialog.current?.close()} />
      </dialog>
    </div>
  );
}
