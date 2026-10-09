import "./app-ui.css";
import { Glyph, type GlyphName } from "./app-icons";
import { TONE_STOP, type Tone } from "./tokens";

/**
 * A text field on the glass material: a label above, the control with an optional leading glyph, and a line of help
 * or error text below. Focus draws the tone on the border. `multiline` makes it a textarea. Pass `value` and
 * `onChange` to control it, or `defaultValue` to let it keep its own text.
 */
export function AppTextField({
  label,
  type = "text",
  placeholder,
  help,
  error,
  glyph,
  size,
  tone = "deep-space",
  multiline,
  value,
  defaultValue,
  onChange,
  disabled,
}: {
  label: string;
  type?: "text" | "search" | "email" | "number";
  placeholder?: string;
  help?: string;
  error?: string;
  glyph?: GlyphName;
  size?: "sm";
  tone?: Tone;
  multiline?: boolean;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  disabled?: boolean;
}) {
  const state = value === undefined ? { defaultValue } : { value };
  const common = {
    placeholder,
    disabled,
    "aria-invalid": error ? true : undefined,
    onChange: onChange ? (e: { target: { value: string } }) => onChange(e.target.value) : undefined,
    ...state,
  };
  const cls = ["app-ui app-field", size && `is-${size}`, error && "is-error"].filter(Boolean).join(" ");
  return (
    <label className={cls} style={{ ["--tone" as string]: `var(--color-${TONE_STOP[tone]})` }}>
      <span className="app-label-md">{label}</span>
      <span className="app-field-control">
        {glyph && <Glyph name={glyph} />}
        {multiline ? <textarea rows={3} {...common} /> : <input type={type} {...common} />}
      </span>
      {(error || help) && <span className="app-label-sm app-field-help">{error ?? help}</span>}
    </label>
  );
}
