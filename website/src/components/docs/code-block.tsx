"use client";

import { useState, type ReactNode } from "react";

export function CopyButton({
  text,
  label = "Copy",
}: {
  text: string;
  label?: string;
}) {
  const [status, setStatus] = useState<"idle" | "copied" | "error">("idle");
  async function copy() {
    try {
      await navigator.clipboard.writeText(text);
      setStatus("copied");
      setTimeout(() => setStatus("idle"), 2000);
    } catch {
      setStatus("error");
    }
  }
  return (
    <button
      type="button"
      className="docs-copy"
      onClick={copy}
      aria-label={status === "copied" ? "Copied" : `${label} to clipboard`}
    >
      <svg
        width="14"
        height="14"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        aria-hidden="true"
      >
        {status === "copied" ? (
          <path d="m5 12 5 5 9-10" />
        ) : (
          <>
            <rect x="9" y="9" width="11" height="11" rx="2" />
            <path d="M5 15V6a2 2 0 0 1 2-2h9" />
          </>
        )}
      </svg>
      <span aria-live="polite">
        {status === "copied"
          ? "Copied"
          : status === "error"
            ? "Select code to copy"
            : label}
      </span>
    </button>
  );
}

function highlight(line: string): ReactNode {
  const trimmed = line.trimStart();
  if (
    trimmed.startsWith("/*") ||
    trimmed.startsWith("*") ||
    trimmed.startsWith("//")
  )
    return <span className="docs-code-comment">{line}</span>;
  return line
    .split(
      /(@(?:theme|utility|import|layer)\b|--[\w-]+|"[^"\n]*"|'[^'\n]*'|#[0-9a-fA-F]{3,8}\b)/g,
    )
    .map((part, index) => {
      const kind = /^@/.test(part)
        ? "keyword"
        : /^--/.test(part)
          ? "tag"
          : /^["'#]/.test(part)
            ? "string"
            : undefined;
      return (
        <span key={index} className={kind ? `docs-code-${kind}` : undefined}>
          {part}
        </span>
      );
    });
}

export function CodeBlock({
  code,
  filename,
  lang,
  embedded = false,
}: {
  code: string;
  filename?: string;
  lang?: string;
  embedded?: boolean;
}) {
  const source = code.replace(/\n$/, "");
  const label = filename ?? lang ?? "code";
  return (
    <div className="docs-code" data-embedded={embedded || undefined}>
      {!embedded && (
        <div className="docs-code-header">
          <span>{label}</span>
          <CopyButton text={source} />
        </div>
      )}
      <pre tabIndex={0} aria-label={label}>
        <code>
          {source.split("\n").map((line, index) => (
            <span className="docs-code-line" key={index}>
              <span className="docs-line-number" aria-hidden="true">
                {index + 1}
              </span>
              <span>{highlight(line)}</span>
            </span>
          ))}
        </code>
      </pre>
    </div>
  );
}
