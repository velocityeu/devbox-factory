# Component Patterns

## Card Component

Glass-morphism card with hover effect:

```tsx
'use client'
import { ReactNode } from 'react'
import { motion } from 'framer-motion'

interface CardProps {
  children: ReactNode
  className?: string
  hover?: boolean
  delay?: number
  padding?: 'sm' | 'default' | 'lg'
}

export default function Card({
  children,
  className = '',
  hover = true,
  delay = 0,
  padding = 'default',
}: CardProps) {
  const paddingStyles = {
    sm: 'p-4 md:p-5',
    default: 'p-5 md:p-6',
    lg: 'p-6 md:p-8',
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.4, delay, ease: [0.25, 0.1, 0.25, 1] }}
      className={`card ${paddingStyles[padding]} ${hover ? 'hover:border-[var(--color-accent)]/20' : ''} ${className}`}
    >
      {children}
    </motion.div>
  )
}
```

Card CSS (in globals.css):
```css
.card {
  @apply relative rounded-2xl;
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  box-shadow: var(--card-shadow);
  backdrop-filter: blur(20px);
  transition: all 0.3s cubic-bezier(0.25, 0.1, 0.25, 1);
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px -8px rgba(0, 0, 0, 0.1);
}
```

## Button Component

Three variants: primary, secondary, ghost:

```tsx
'use client'
import Link from 'next/link'
import { ReactNode } from 'react'

interface ButtonProps {
  children: ReactNode
  href?: string
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'default' | 'lg'
  className?: string
  onClick?: () => void
}

export default function Button({
  children,
  href,
  variant = 'primary',
  size = 'default',
  className = '',
  onClick,
}: ButtonProps) {
  const baseStyles = 'inline-flex items-center justify-center gap-2 font-medium rounded-full transition-all duration-300'

  const variants = {
    primary: 'bg-[var(--color-accent)] text-white hover:bg-[var(--color-accent-hover)]',
    secondary: 'bg-[var(--color-bg-secondary)] text-primary border border-[var(--color-border)] hover:border-[var(--color-accent)]',
    ghost: 'text-secondary hover:text-primary hover:bg-[var(--color-bg-secondary)]',
  }

  const sizes = {
    sm: 'px-4 py-2 text-sm',
    default: 'px-5 py-2.5 text-sm',
    lg: 'px-6 py-3 text-base',
  }

  const classes = `${baseStyles} ${variants[variant]} ${sizes[size]} ${className}`

  if (href) {
    return href.startsWith('#') || href.startsWith('/') ? (
      <Link href={href} className={classes}>{children}</Link>
    ) : (
      <a href={href} target="_blank" rel="noopener noreferrer" className={classes}>{children}</a>
    )
  }

  return <button onClick={onClick} className={classes}>{children}</button>
}
```

## Section Badge

Small label above section headings:

```css
.section-badge {
  @apply inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-full;
  background: var(--color-bg-secondary);
  color: var(--color-text-secondary);
}
```

Usage:
```tsx
<span className="section-badge mb-4">Section Label</span>
<h2 className="text-display text-primary">
  Heading with <span className="gradient-text">accent</span>
</h2>
```

## Terminal Component

For code/command display:

```tsx
'use client'
import { ReactNode } from 'react'

interface TerminalProps {
  title?: string
  children: ReactNode
}

export default function Terminal({ title = 'Terminal', children }: TerminalProps) {
  return (
    <div className="terminal">
      <div className="terminal-header">
        <div className="flex gap-1.5">
          <span className="w-3 h-3 rounded-full bg-red-500/80" />
          <span className="w-3 h-3 rounded-full bg-yellow-500/80" />
          <span className="w-3 h-3 rounded-full bg-green-500/80" />
        </div>
        <span className="ml-3 text-xs text-gray-500">{title}</span>
      </div>
      <div className="terminal-body">{children}</div>
    </div>
  )
}
```

Terminal CSS:
```css
.terminal {
  @apply rounded-xl overflow-hidden font-mono text-sm;
  background: #1d1d1f;
  border: 1px solid #424245;
}

.terminal-header {
  @apply flex items-center gap-2 px-4 py-3 border-b;
  background: #2d2d30;
  border-color: #424245;
}

.terminal-body {
  @apply p-4 text-gray-300;
}
```

## Mobile Navigation

Slide-out drawer with solid background:

```tsx
// Key patterns for mobile nav:

// 1. Separate overlay and panel for proper z-index
{isMenuOpen && (
  <div className="fixed inset-0 bg-black/50 z-[60] md:hidden" onClick={() => setIsMenuOpen(false)} />
)}

// 2. Panel with solid background and shadow
<div className={`
  fixed top-0 right-0 h-full w-72 max-w-[80vw]
  bg-[var(--color-bg)] border-l border-[var(--color-border)]
  transform transition-transform duration-300 md:hidden z-[70]
  shadow-2xl
  ${isMenuOpen ? 'translate-x-0' : 'translate-x-full'}
`}>

// 3. Close button inside panel
<button onClick={() => setIsMenuOpen(false)} className="absolute top-5 right-5 p-2">
  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
  </svg>
</button>
```

## Theme Toggle

Animated sun/moon toggle:

```tsx
'use client'
import { useTheme } from '../ThemeProvider'
import { motion, AnimatePresence } from 'framer-motion'

export default function ThemeToggle() {
  const { resolvedTheme, setTheme, mounted } = useTheme()

  if (!mounted) return <div className="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800" />

  return (
    <button
      onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
      className="w-10 h-10 flex items-center justify-center rounded-full bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
    >
      <AnimatePresence mode="wait">
        {resolvedTheme === 'dark' ? (
          <motion.svg key="sun" initial={{ opacity: 0, rotate: -90 }} animate={{ opacity: 1, rotate: 0 }} exit={{ opacity: 0, rotate: 90 }} className="w-5 h-5 text-yellow-400" /* sun icon */ />
        ) : (
          <motion.svg key="moon" initial={{ opacity: 0, rotate: 90 }} animate={{ opacity: 1, rotate: 0 }} exit={{ opacity: 0, rotate: -90 }} className="w-5 h-5 text-gray-700" /* moon icon */ />
        )}
      </AnimatePresence>
    </button>
  )
}
```

## Copy Button

For code snippets:

```tsx
'use client'
import { useState } from 'react'

export default function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <button onClick={handleCopy} className="p-2 rounded-lg hover:bg-white/10 transition-colors shrink-0">
      {copied ? (
        <svg className="w-4 h-4 text-emerald-400" /* check icon */ />
      ) : (
        <svg className="w-4 h-4 text-gray-400" /* copy icon */ />
      )}
    </button>
  )
}
```

## Animation Patterns

Use Framer Motion with these defaults:

```tsx
// Fade in from below (most common)
initial={{ opacity: 0, y: 16 }}
whileInView={{ opacity: 1, y: 0 }}
viewport={{ once: true }}
transition={{ duration: 0.5 }}

// Staggered cards
delay={index * 0.05}

// Apple-style easing
ease: [0.25, 0.1, 0.25, 1]

// Or use Tailwind:
transition={{ duration: 0.3, ease: 'ease-apple' }}
```

## Typography Scale

```typescript
fontSize: {
  'display-xl': ['5rem', { lineHeight: '1', letterSpacing: '-0.03em', fontWeight: '600' }],
  'display-lg': ['3.5rem', { lineHeight: '1.1', letterSpacing: '-0.025em', fontWeight: '600' }],
  'display': ['2.5rem', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '600' }],
  'title': ['1.75rem', { lineHeight: '1.3', letterSpacing: '-0.015em', fontWeight: '600' }],
}
```

Usage:
```tsx
<h1 className="text-display-lg md:text-display-xl text-primary">Heading</h1>
<h2 className="text-display text-primary">Section Heading</h2>
<h3 className="text-title text-primary">Subsection</h3>
```
