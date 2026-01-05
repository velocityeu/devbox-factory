/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  basePath: '/devbox-factory',
  trailingSlash: true,
}

module.exports = nextConfig
