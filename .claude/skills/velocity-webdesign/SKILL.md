---
name: velocity-webdesign
description: Create modern, minimal websites with Next.js 14 and Tailwind CSS. Apple-inspired design with dark/light theme support. Use when building landing pages, marketing sites, or product pages. Triggers on "website", "landing page", "redesign", "Next.js site", "Tailwind site".
---

# Velocity Web Design Skill

A comprehensive system for building modern, minimal websites inspired by Apple's design language.

## Design Philosophy

Follow these core principles:

1. **Simplicity with Soul** - Remove clutter but preserve meaning. Every element must have purpose.
2. **Clarity Over Decoration** - No gradients, no emojis, no visual noise. Let content speak.
3. **Muted Sophistication** - Use soft metallics, neutral tones, and restrained color palette.
4. **White Space is Sacred** - Generous spacing creates breathing room and hierarchy.
5. **Typography First** - Clean fonts, proper hierarchy, no unnecessary decorations.

## Quick Start

For a new website project:

```bash
# Initialize Next.js with TypeScript and Tailwind
npx create-next-app@latest docs --typescript --tailwind --app --src-dir=false

# Install dependencies
cd docs && npm install framer-motion
```

## Tech Stack

- **Framework**: Next.js 14 (App Router, Static Export)
- **Styling**: Tailwind CSS with CSS Variables
- **Animations**: Framer Motion
- **Fonts**: Inter (sans), JetBrains Mono (code)

## Additional Resources

- For color system and theming, see [colors.md](colors.md)
- For component patterns, see [components.md](components.md)
- For complete code examples, see [examples.md](examples.md)

## File Structure

```
docs/
├── app/
│   ├── layout.tsx       # Root layout with ThemeProvider
│   ├── page.tsx         # Main page composing sections
│   └── globals.css      # Tailwind + CSS variables
├── components/
│   ├── Navbar.tsx       # Sticky nav with mobile menu
│   ├── Hero.tsx         # Hero section
│   ├── [sections].tsx   # Content sections
│   ├── Footer.tsx       # Footer with CTA
│   ├── ThemeProvider.tsx # Theme context
│   └── ui/
│       ├── Button.tsx   # Button variants
│       ├── Card.tsx     # Glass card
│       ├── Terminal.tsx # Code display
│       └── ThemeToggle.tsx
├── tailwind.config.ts
├── next.config.js       # output: 'export' for static
└── package.json
```

## Critical Patterns

### No Emojis Rule
Replace emojis with:
- Numbered indicators (01, 02, 03)
- Text initials for avatars (VC, TL)
- Simple SVG icons (checkmarks, arrows)
- Clean typography

### Color Restraint
- Single accent color only (Apple blue)
- No purple, no gradients
- Muted success/error colors
- Let neutrals dominate

### Mobile-First
- Base styles for mobile
- Breakpoints: sm (640px), md (768px), lg (1024px)
- Touch targets minimum 44px
- Simplified layouts that stack naturally
