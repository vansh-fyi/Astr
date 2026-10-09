import type { ReactNode } from "react";

/** A numbered chain of steps with connectors. The last step can be marked as the outcome. */
export function Flow({
  steps,
}: {
  steps: { title: string; text: ReactNode; outcome?: boolean }[];
}) {
  return (
    <ol className="viz-flow">
      {steps.map((s, i) => (
        <li key={i} data-outcome={s.outcome || undefined}>
          <span className="viz-flow-n" aria-hidden="true">
            {i + 1}
          </span>
          <div>
            <strong>{s.title}</strong>
            <p>{s.text}</p>
          </div>
        </li>
      ))}
    </ol>
  );
}
