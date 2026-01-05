'use client'

import { ReactNode } from 'react'

interface TerminalProps {
  title?: string
  children: ReactNode
  className?: string
}

export default function Terminal({
  title = 'PowerShell',
  children,
  className = '',
}: TerminalProps) {
  return (
    <div className={`rounded-xl overflow-hidden border border-white/10 shadow-2xl ${className}`}>
      {/* Header */}
      <div className="flex items-center px-4 py-3 bg-background-tertiary border-b border-white/10">
        <div className="flex gap-2">
          <span className="w-3 h-3 rounded-full bg-red-500" />
          <span className="w-3 h-3 rounded-full bg-yellow-500" />
          <span className="w-3 h-3 rounded-full bg-green-500" />
        </div>
        <span className="flex-1 text-center text-xs text-zinc-500 font-mono">{title}</span>
      </div>

      {/* Body */}
      <div className="bg-background-secondary p-4 md:p-5 font-mono text-sm leading-relaxed overflow-x-auto">
        {children}
      </div>
    </div>
  )
}

interface TerminalLineProps {
  prompt?: string
  command?: string
  children?: ReactNode
  className?: string
}

export function TerminalLine({
  prompt = 'PS C:\\>',
  command,
  children,
  className = '',
}: TerminalLineProps) {
  if (command) {
    return (
      <div className={`flex gap-2 ${className}`}>
        <span className="text-accent-cyan shrink-0">{prompt}</span>
        <span className="text-white">{command}</span>
      </div>
    )
  }

  return <div className={className}>{children}</div>
}

interface TerminalOutputProps {
  lines: Array<{
    text: string
    type?: 'success' | 'error' | 'highlight' | 'default'
    icon?: string
  }>
}

export function TerminalOutput({ lines }: TerminalOutputProps) {
  const typeStyles = {
    success: 'text-green-400',
    error: 'text-red-400',
    highlight: 'text-accent-primary font-semibold mt-3 p-3 bg-accent-primary/10 rounded-lg',
    default: 'text-zinc-400',
  }

  return (
    <div className="mt-3 space-y-1">
      {lines.map((line, i) => (
        <div key={i} className={typeStyles[line.type || 'default']}>
          {line.icon && <span className="mr-2">{line.icon}</span>}
          {line.text}
        </div>
      ))}
    </div>
  )
}
