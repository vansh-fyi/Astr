"use client";

import { useId, useState, type KeyboardEvent, type ReactNode } from "react";

type Tab = "first" | "second";

export function CodeTabsClient({
  first,
  second,
  labels,
}: {
  first: ReactNode;
  second?: ReactNode;
  labels: [string, string];
}) {
  const id = useId();
  const [active, setActive] = useState<Tab>("first");
  const tabs: { key: Tab; label: string }[] = [
    { key: "first", label: labels[0] },
    ...(second ? [{ key: "second" as const, label: labels[1] }] : []),
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
            className="docs-tab app-ui app-button is-glass is-sm"
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
        id={`${id}-panel-first`}
        aria-labelledby={`${id}-tab-first`}
        className="docs-tabpanel"
        hidden={active !== "first"}
      >
        {first}
      </div>
      {second && (
        <div
          role="tabpanel"
          id={`${id}-panel-second`}
          aria-labelledby={`${id}-tab-second`}
          className="docs-tabpanel"
          hidden={active !== "second"}
        >
          {second}
        </div>
      )}
    </div>
  );
}
