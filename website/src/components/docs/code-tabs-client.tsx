"use client";

import { useId, useState, type KeyboardEvent, type ReactNode } from "react";

type Tab = "css" | "flutter";

export function CodeTabsClient({
  css,
  flutter,
}: {
  css: ReactNode;
  flutter?: ReactNode;
}) {
  const id = useId();
  const [active, setActive] = useState<Tab>("css");
  const tabs: { key: Tab; label: string }[] = [
    { key: "css", label: "Tokens / CSS" },
    ...(flutter ? [{ key: "flutter" as const, label: "Flutter" }] : []),
  ];

  function onKeyDown(event: KeyboardEvent<HTMLDivElement>) {
    if (tabs.length < 2) return;
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
    event.preventDefault();
    const next = tabs[(tabs.findIndex((t) => t.key === active) + 1) % tabs.length];
    setActive(next.key);
    document.getElementById(`${id}-tab-${next.key}`)?.focus();
  }

  return (
    <div className="docs-tabs">
      <div
        className="docs-tablist"
        role="tablist"
        aria-label="Code format"
        onKeyDown={onKeyDown}
      >
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            role="tab"
            id={`${id}-tab-${tab.key}`}
            className="docs-tab"
            aria-selected={active === tab.key}
            aria-controls={`${id}-panel-${tab.key}`}
            tabIndex={active === tab.key ? 0 : -1}
            onClick={() => setActive(tab.key)}
          >
            {tab.label}
          </button>
        ))}
      </div>
      <div
        role="tabpanel"
        id={`${id}-panel-css`}
        aria-labelledby={`${id}-tab-css`}
        className="docs-tabpanel"
        hidden={active !== "css"}
      >
        {css}
      </div>
      {flutter && (
        <div
          role="tabpanel"
          id={`${id}-panel-flutter`}
          aria-labelledby={`${id}-tab-flutter`}
          className="docs-tabpanel"
          hidden={active !== "flutter"}
        >
          {flutter}
        </div>
      )}
    </div>
  );
}
