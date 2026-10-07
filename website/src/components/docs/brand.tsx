export function AstrMark({ size = 19 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
    >
      <path d="M12 2c.6 5.4 3.4 8.9 10 10-6.6 1.1-9.4 4.6-10 10-.6-5.4-3.4-8.9-10-10 6.6-1.1 9.4-4.6 10-10Z" />
    </svg>
  );
}

export function Wordmark() {
  return <span>Astr</span>;
}
