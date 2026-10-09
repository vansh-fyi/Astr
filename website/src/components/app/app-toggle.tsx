import "./app-ui.css";
import { TONE_STOP, type Tone } from "./tokens";

/**
 * A switch for a setting that is on or off. It is a real checkbox with the switch role, so it works with the
 * keyboard and screen readers; the track and thumb are drawn in CSS. Pass `checked` and `onChange` to control it, or
 * `defaultChecked` to let it keep its own state.
 */
export function AppToggle({
  label,
  hideLabel,
  tone = "deep-space",
  size,
  checked,
  defaultChecked,
  onChange,
  disabled,
}: {
  label: string;
  /** Keep the label for assistive technology but do not draw it. */
  hideLabel?: boolean;
  tone?: Tone;
  size?: "sm";
  checked?: boolean;
  defaultChecked?: boolean;
  onChange?: (checked: boolean) => void;
  disabled?: boolean;
}) {
  const state = checked === undefined ? { defaultChecked } : { checked };
  return (
    <label className={`app-ui app-toggle${size ? ` is-${size}` : ""}`} style={{ ["--tone" as string]: `var(--color-${TONE_STOP[tone]})` }}>
      <input type="checkbox" role="switch" aria-label={hideLabel ? label : undefined} disabled={disabled} onChange={onChange ? (e) => onChange(e.target.checked) : undefined} {...state} />
      <span className="app-toggle-track" aria-hidden="true">
        <span className="app-toggle-thumb" />
      </span>
      {!hideLabel && <span className="app-label-md">{label}</span>}
    </label>
  );
}
