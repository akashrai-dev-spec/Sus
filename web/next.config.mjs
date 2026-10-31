/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  eslint: {
    ignoreDuringBuilds: true,
  },
  ...(process.env.NEXT_PUBLIC_SERVER_URL && {
    env: {
      NEXT_PUBLIC_SERVER_URL: process.env.NEXT_PUBLIC_SERVER_URL,
    },
  }),
  ...(process.env.NEXT_PUBLIC_SOCKET_URL && {
    env: {
      NEXT_PUBLIC_SOCKET_URL: process.env.NEXT_PUBLIC_SOCKET_URL,
    },
  }),
};

export default nextConfig;
