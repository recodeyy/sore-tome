/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Backend API base is read server-side for the BFF proxy routes.
  env: {
    NEXT_PUBLIC_APP_NAME: "SERO Control",
  },
  webpack: (config) => {
    // Node 24 on Windows returns EISDIR from fs.readlink on regular files, which
    // webpack's symlink resolution + PackFileCache snapshotter do not tolerate.
    // Scope the workaround to Windows so AWS Linux builds keep their FS cache.
    if (process.platform === "win32") {
      config.resolve.symlinks = false;
      config.cache = false;
    }
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
