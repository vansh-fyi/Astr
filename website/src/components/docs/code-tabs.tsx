import type { ReactNode } from "react";

export function CodeTabs({ children }: { children: ReactNode }) {
  return (
    <div className="docs-tabs">
      <div className="docs-tablist" role="tablist" aria-label="Code format">
        <button
          type="button"
          role="tab"
          id="tab-css"
          className="docs-tab"
          aria-selected="true"
          aria-controls="panel-css"
        >
          Tokens / CSS
        </button>
        <button
          type="button"
          role="tab"
          className="docs-tab"
          disabled
          aria-disabled="true"
        >
          Flutter
          <span className="docs-tab-soon">Coming soon</span>
        </button>
      </div>
      <div
        role="tabpanel"
        id="panel-css"
        aria-labelledby="tab-css"
        className="docs-tabpanel"
      >
        {children}
      </div>
    </div>
  );
}
