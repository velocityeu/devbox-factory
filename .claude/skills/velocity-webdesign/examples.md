# Complete Code Examples

## Project Setup Files

### package.json

```json
{
  "name": "my-website",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "framer-motion": "^11.0.0",
    "next": "14.2.35",
    "react": "^18",
    "react-dom": "^18"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10",
    "postcss": "^8",
    "tailwindcss": "^3.4.0",
    "typescript": "^5"
  }
}
```

### next.config.js (Static Export)

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
}

module.exports = nextConfig
```

### tailwind.config.ts

```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        gray: {
          50: '#fafafa',
          100: '#f5f5f7',
          200: '#e8e8ed',
          300: '#d2d2d7',
          400: '#a1a1a6',
          500: '#86868b',
          600: '#6e6e73',
          700: '#424245',
          800: '#2d2d30',
          850: '#1d1d1f',
          900: '#161617',
          950: '#0a0a0b',
        },
        primary: {
          500: '#0071e3',
          600: '#0058b0',
        },
      },
      fontFamily: {
        sans: ['Inter', 'SF Pro Display', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'SF Mono', 'monospace'],
      },
      fontSize: {
        'display-xl': ['5rem', { lineHeight: '1', letterSpacing: '-0.03em', fontWeight: '600' }],
        'display-lg': ['3.5rem', { lineHeight: '1.1', letterSpacing: '-0.025em', fontWeight: '600' }],
        'display': ['2.5rem', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '600' }],
        'title': ['1.75rem', { lineHeight: '1.3', letterSpacing: '-0.015em', fontWeight: '600' }],
      },
      transitionTimingFunction: {
        'apple': 'cubic-bezier(0.25, 0.1, 0.25, 1)',
      },
    },
  },
  plugins: [],
}

export default config
```

### app/layout.tsx

```tsx
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { ThemeProvider } from '@/components/ThemeProvider'

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })

export const metadata: Metadata = {
  title: 'My Website',
  description: 'A modern, minimal website',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){try{var t=localStorage.getItem('theme');if(t==='dark'||(!t&&window.matchMedia('(prefers-color-scheme:dark)').matches)){document.documentElement.classList.add('dark')}}catch(e){}})();`,
          }}
        />
      </head>
      <body className="font-sans antialiased">
        <ThemeProvider>
          <div className="fixed inset-0 -z-10 bg-[var(--color-bg)]" />
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
```

## Section Examples

### Hero Section

```tsx
'use client'
import { motion } from 'framer-motion'
import Button from './ui/Button'

export default function Hero() {
  return (
    <header className="min-h-screen flex flex-col justify-center items-center px-5 pt-24 pb-20">
      <div className="max-w-4xl mx-auto text-center">
        {/* Badge */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          className="section-badge mb-6"
        >
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          <span>Now available</span>
        </motion.div>

        {/* Title */}
        <motion.h1
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="text-display-lg md:text-display-xl text-primary mb-6"
        >
          Your main headline.
          <br />
          <span className="gradient-text">With accent text.</span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="text-lg md:text-xl text-secondary max-w-2xl mx-auto mb-10"
        >
          A compelling description that explains your value proposition clearly and concisely.
        </motion.p>

        {/* CTA */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="flex flex-col sm:flex-row gap-4 justify-center"
        >
          <Button href="#quickstart" variant="primary" size="lg">
            Get Started
          </Button>
          <Button href="#demo" variant="secondary" size="lg">
            Learn More
          </Button>
        </motion.div>
      </div>
    </header>
  )
}
```

### Features Grid (No Emojis)

```tsx
'use client'
import { motion } from 'framer-motion'
import Card from './ui/Card'

const features = [
  {
    title: 'Feature One',
    items: ['Benefit A', 'Benefit B', 'Benefit C', 'Benefit D'],
  },
  {
    title: 'Feature Two',
    items: ['Benefit A', 'Benefit B', 'Benefit C', 'Benefit D'],
  },
  // ... more features
]

export default function Features() {
  return (
    <section className="py-24 md:py-32 px-5">
      <div className="max-w-6xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">Features</span>
          <h2 className="text-display text-primary mb-4">
            What we <span className="gradient-text">offer</span>
          </h2>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {features.map((feature, index) => (
            <Card key={feature.title} delay={index * 0.05}>
              <h3 className="text-lg font-semibold text-primary mb-4">{feature.title}</h3>
              <ul className="space-y-2">
                {feature.items.map((item) => (
                  <li key={item} className="flex items-center gap-2 text-sm text-secondary">
                    <svg className="w-4 h-4 text-emerald-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                    {item}
                  </li>
                ))}
              </ul>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
```

### Problem Cards with Numbers (Not Emojis)

```tsx
const problems = [
  { num: '01', title: 'Problem One', description: 'Description of the problem.' },
  { num: '02', title: 'Problem Two', description: 'Description of the problem.' },
  { num: '03', title: 'Problem Three', description: 'Description of the problem.' },
]

// In component:
{problems.map((problem, index) => (
  <Card key={problem.title} delay={index * 0.05}>
    <span className="text-xs font-mono text-tertiary mb-3 block">{problem.num}</span>
    <h3 className="text-lg font-semibold text-primary mb-2">{problem.title}</h3>
    <p className="text-secondary text-sm">{problem.description}</p>
  </Card>
))}
```

### Testimonials with Initials (Not Emoji Avatars)

```tsx
const testimonials = [
  {
    quote: 'This product changed everything for us.',
    initials: 'JD',
    name: 'John Doe',
    role: 'CEO, Company',
  },
  // ...
]

// In component:
<div className="flex items-center gap-3 pt-4 border-t border-[var(--color-border-light)]">
  <span className="w-10 h-10 flex items-center justify-center bg-[var(--color-bg-secondary)] border border-[var(--color-border-light)] rounded-full text-sm font-medium text-secondary">
    {testimonial.initials}
  </span>
  <div>
    <span className="block font-medium text-primary text-sm">{testimonial.name}</span>
    <span className="text-xs text-tertiary">{testimonial.role}</span>
  </div>
</div>
```

## GitHub Actions Deployment

For GitHub Pages deployment, create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: docs/package-lock.json
      - name: Install & Build
        working-directory: docs
        run: |
          npm ci
          npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: docs/out

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/deploy-pages@v4
        id: deployment
```

## Responsive Patterns

### Mobile-First Grid

```tsx
// 1 column on mobile, 2 on tablet, 3 on desktop
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">

// 1 column on mobile, 2 on tablet, 5 on large desktop
<div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
```

### Responsive Typography

```tsx
<h1 className="text-display-lg md:text-display-xl">
<h2 className="text-display">
<p className="text-lg md:text-xl">
```

### Responsive Spacing

```tsx
<section className="py-24 md:py-32 px-5">
<div className="p-5 md:p-6">
<div className="gap-4 md:gap-6">
```
