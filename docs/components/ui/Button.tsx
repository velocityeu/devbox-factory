'use client'

import { ReactNode } from 'react'

interface ButtonProps {
  children: ReactNode
  variant?: 'primary' | 'secondary'
  size?: 'default' | 'large'
  href?: string
  onClick?: () => void
  className?: string
  glow?: boolean
}

export default function Button({
  children,
  variant = 'primary',
  size = 'default',
  href,
  onClick,
  className = '',
  glow = false,
}: ButtonProps) {
  const baseStyles = 'inline-flex items-center justify-center gap-2 font-semibold rounded-xl transition-all duration-300 active:scale-95'

  const variants = {
    primary: 'bg-gradient-primary text-white hover:shadow-lg hover:shadow-accent-primary/25 hover:-translate-y-0.5',
    secondary: 'bg-white/5 border border-white/10 text-white hover:bg-white/10 hover:border-accent-primary/50',
  }

  const sizes = {
    default: 'px-6 py-3 text-sm md:text-base',
    large: 'px-8 py-4 text-base md:text-lg',
  }

  const classes = `${baseStyles} ${variants[variant]} ${sizes[size]} ${glow ? 'btn-glow' : ''} ${className}`

  if (href) {
    return (
      <a href={href} className={classes}>
        {children}
      </a>
    )
  }

  return (
    <button onClick={onClick} className={classes}>
      {children}
    </button>
  )
}
