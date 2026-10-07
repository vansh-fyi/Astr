import createMDX from "@next/mdx";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {};

// String plugin names resolve in both the webpack loader and Turbopack.
// throwOnError makes a malformed formula fail the build; `trust` stays off.
const withMDX = createMDX({
  options: {
    remarkPlugins: ["remark-math"],
    rehypePlugins: [["rehype-katex", { throwOnError: true }]],
  },
});

export default withMDX(nextConfig);
