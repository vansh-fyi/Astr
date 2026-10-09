"use client";

import { useEffect, useRef, useState } from "react";

/** Width in pixels of the element a ref is attached to, kept current with a ResizeObserver. */
export function useElementWidth<T extends HTMLElement>(fallback: number): [React.RefObject<T | null>, number] {
  const ref = useRef<T | null>(null);
  const [width, setWidth] = useState(fallback);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const read = (): void => setWidth(Math.max(1, Math.round(el.getBoundingClientRect().width)));
    read();
    const observer = new ResizeObserver(read);
    observer.observe(el);
    return () => observer.disconnect();
  }, []);
  return [ref, width];
}
