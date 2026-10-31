/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  ...(process.env.NEXT_PUBLIC_SERVER_URL && {
    env: {
      NEXT_PUBLIC_SERVER_URL: process.env.NEXT_PUBLIC_SERVER_URL,
    },
  }),
};

export default nextConfig;
