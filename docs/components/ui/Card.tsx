'use client'

import { ReactNode } from 'react'
import { motion } from 'framer-motion'

interface CardProps {
  children: ReactNode
  className?: string
  hover?: boolean
  delay?: number
}

export default function Card({
  children,
  className = '',
  hover = true,
  delay = 0,
}: CardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-50px' }}
      transition={{ duration: 0.5, delay }}
      className={`
        glass-card p-6 md:p-8
        ${hover ? 'transition-all duration-300 hover:border-accent-primary/30 hover:-translate-y-1 hover:shadow-xl hover:shadow-accent-primary/5' : ''}
        ${className}
      `}
    >
      {children}
    </motion.div>
  )
}
