"use client";

import { useState } from "react";

export function ColorChip({
  step,
  value,
  label,
}: {
  step: number;
  value: string;
  label: string;
}) {
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState(false);
  async function copy() {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setError(false);
      setTimeout(() => setCopied(false), 1600);
    } catch {
      setError(true);
    }
  }
  return (
    <button
      type="button"
      className="docs-color-chip"
      onClick={copy}
      aria-label={`Copy ${label} ${value}`}
      title={`${label} ${value}`}
    >
      <span style={{ backgroundColor: value }} />
      <strong>{step}</strong>
      <small aria-live="polite">
        {copied ? "Copied" : error ? "Copy failed" : value}
      </small>
    </button>
  );
}
