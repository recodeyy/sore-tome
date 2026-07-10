import path from "node:path";

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Backend API base is read server-side for the BFF proxy routes.
  env: {
    NEXT_PUBLIC_APP_NAME: "SERO Control",
  },
  experimental: {
    // DEPLOY FIX: the Windows output-file tracer systematically drops Next.js's
    // conditionally-required vendored internals (e.g. `@swc/helpers`,
    // `next/dist/compiled/@opentelemetry/api`), producing Lambda
    // "Cannot find module ..." crashes on every route. Force-include the whole
    // set of runtime deps so OpenNext always bundles them into the server function.
    outputFileTracingIncludes: {
      "*": [
        "./node_modules/next/**/*",
        "./node_modules/@next/**/*",
        "./node_modules/@swc/helpers/**/*",
        "./node_modules/styled-jsx/**/*",
      ],
    },
  },
  webpack: (config) => {
    // Node 24 on Windows returns EISDIR from fs.readlink on regular files, which
    // webpack's symlink resolution + PackFileCache snapshotter do not tolerate.
    // Scope the workaround to Windows so AWS Linux builds keep their FS cache.
    if (process.platform === "win32") {
      config.resolve.symlinks = false;
      config.cache = false;
    }
    // Explicit "@/*" -> ./src alias so path resolution is deterministic on Linux
    // (case-sensitive) builds regardless of tsconfig baseUrl handling.
    config.resolve.alias = {
      ...(config.resolve.alias || {}),
      "@": path.resolve(process.cwd(), "src"),
    };
    return config;
  },
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "microphone=(self)" },
        ],
      },
    ];
  },
};

export default nextConfig;
