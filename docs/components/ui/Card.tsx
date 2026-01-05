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
      className={`
        card ${paddingStyles[padding]}
        ${hover ? 'hover:border-[var(--color-accent)]/20' : ''}
        ${className}
      `}
    >
      {children}
    </motion.div>
  )
}
