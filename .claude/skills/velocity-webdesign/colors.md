# Color System & Theming

## CSS Variables Approach

Use CSS variables for seamless light/dark theme switching. Define in `globals.css`:

```css
@layer base {
  :root {
    /* Light theme */
    --color-bg: #ffffff;
    --color-bg-secondary: #f5f5f7;
    --color-bg-tertiary: #fafafa;
    --color-text: #1d1d1f;
    --color-text-secondary: #6e6e73;
    --color-text-tertiary: #86868b;
    --color-border: #d2d2d7;
    --color-border-light: #e8e8ed;
    --color-accent: #0071e3;
    --color-accent-hover: #0058b0;

    /* Card styles */
    --card-bg: rgba(255, 255, 255, 0.8);
    --card-border: rgba(0, 0, 0, 0.06);
    --card-shadow: 0 2px 8px -2px rgba(0, 0, 0, 0.05), 0 4px 16px -4px rgba(0, 0, 0, 0.08);
  }

  .dark {
    --color-bg: #000000;
    --color-bg-secondary: #161617;
    --color-bg-tertiary: #1d1d1f;
    --color-text: #f5f5f7;
    --color-text-secondary: #a1a1a6;
    --color-text-tertiary: #6e6e73;
    --color-border: #424245;
    --color-border-light: #2d2d30;
    --color-accent: #2997ff;
    --color-accent-hover: #0071e3;

    /* Card styles dark */
    --card-bg: rgba(29, 29, 31, 0.8);
    --card-border: rgba(255, 255, 255, 0.08);
    --card-shadow: 0 2px 8px -2px rgba(0, 0, 0, 0.2), 0 4px 16px -4px rgba(0, 0, 0, 0.3);
  }
}
```

## Tailwind Config Colors

```typescript
// tailwind.config.ts
const config: Config = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Apple-inspired neutral palette
        gray: {
          50: '#fafafa',
          100: '#f5f5f7',
          150: '#ebebed',
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
        // Primary accent - Apple blue
        primary: {
          500: '#0071e3',
          600: '#0058b0',
        },
      },
    },
  },
}
```

## Utility Classes

Create these in globals.css for easy use:

```css
@layer utilities {
  .text-primary { color: var(--color-text); }
  .text-secondary { color: var(--color-text-secondary); }
  .text-tertiary { color: var(--color-text-tertiary); }
  .text-accent { color: var(--color-accent); }

  .bg-primary { background-color: var(--color-bg); }
  .bg-secondary { background-color: var(--color-bg-secondary); }
  .bg-tertiary { background-color: var(--color-bg-tertiary); }
}
```

## Accent Color Usage

The accent color should be used sparingly:
- Primary buttons
- Links on hover
- Active states
- Highlighted text (solid, not gradient)
- Small indicators and badges

**Never use gradient text** - use solid accent color:
```css
.gradient-text {
  color: var(--color-accent);
}
```

## Semantic Colors

For success/error states, use muted versions:
- Success: `emerald-500` with `/10` or `/5` backgrounds
- Error: `red-500` with `/10` or `/5` backgrounds
- These are the ONLY non-neutral colors besides the accent blue

## Theme Toggle Implementation

ThemeProvider with localStorage persistence:

```tsx
'use client'
import { createContext, useContext, useEffect, useState, ReactNode } from 'react'

type Theme = 'light' | 'dark' | 'system'

interface ThemeContextType {
  theme: Theme
  resolvedTheme: 'light' | 'dark'
  setTheme: (theme: Theme) => void
  mounted: boolean
}

const ThemeContext = createContext<ThemeContextType>({
  theme: 'system',
  resolvedTheme: 'dark',
  setTheme: () => {},
  mounted: false,
})

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('system')
  const [resolvedTheme, setResolvedTheme] = useState<'light' | 'dark'>('dark')
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    const stored = localStorage.getItem('theme') as Theme | null
    if (stored) setTheme(stored)
  }, [])

  useEffect(() => {
    if (!mounted) return
    const root = document.documentElement
    const resolved = theme === 'system'
      ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
      : theme

    setResolvedTheme(resolved)
    root.classList.toggle('dark', resolved === 'dark')
  }, [theme, mounted])

  const handleSetTheme = (newTheme: Theme) => {
    setTheme(newTheme)
    localStorage.setItem('theme', newTheme)
  }

  return (
    <ThemeContext.Provider value={{ theme, resolvedTheme, setTheme: handleSetTheme, mounted }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  return useContext(ThemeContext)
}
```

## Flash Prevention

Add this script to layout.tsx head to prevent theme flash:

```tsx
<script
  dangerouslySetInnerHTML={{
    __html: `
      (function() {
        try {
          var theme = localStorage.getItem('theme');
          if (theme === 'dark' || (!theme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
            document.documentElement.classList.add('dark');
          }
        } catch (e) {}
      })();
    `,
  }}
/>
```
