'use client'

import { ReactNode } from 'react'

interface ButtonProps {
  children: ReactNode
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'default' | 'lg'
  href?: string
  onClick?: () => void
  className?: string
}

export default function Button({
  children,
  variant = 'primary',
  size = 'default',
  href,
  onClick,
  className = '',
}: ButtonProps) {
  const baseStyles = `
    inline-flex items-center justify-center gap-2
    font-medium rounded-full
    transition-all duration-300 ease-apple
    active:scale-[0.97]
    disabled:opacity-50 disabled:cursor-not-allowed
  `

  const variants = {
    primary: `
      bg-[var(--color-accent)] text-white
      hover:brightness-110
      shadow-sm hover:shadow-md hover:shadow-[var(--color-accent)]/20
    `,
    secondary: `
      bg-[var(--color-bg)] text-[var(--color-accent)]
      border border-[var(--color-border)]
      hover:bg-[var(--color-bg-secondary)] hover:border-[var(--color-accent)]
    `,
    ghost: `
      text-[var(--color-accent)]
      hover:bg-[var(--color-bg-secondary)]
    `,
  }

  const sizes = {
    sm: 'px-4 py-2 text-sm',
    default: 'px-6 py-3 text-sm',
    lg: 'px-8 py-4 text-base',
  }

  const classes = `${baseStyles} ${variants[variant]} ${sizes[size]} ${className}`

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
