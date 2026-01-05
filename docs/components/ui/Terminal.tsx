'use client'

import { ReactNode } from 'react'

interface TerminalProps {
  title?: string
  children: ReactNode
  className?: string
}

export default function Terminal({
  title = 'Terminal',
  children,
  className = '',
}: TerminalProps) {
  return (
    <div className={`terminal shadow-soft-xl ${className}`}>
      {/* Header */}
      <div className="terminal-header">
        <div className="flex gap-2">
          <span className="w-3 h-3 rounded-full bg-[#ff5f56]" />
          <span className="w-3 h-3 rounded-full bg-[#ffbd2e]" />
          <span className="w-3 h-3 rounded-full bg-[#27ca40]" />
        </div>
        <span className="flex-1 text-center text-xs text-gray-500">{title}</span>
        <div className="w-12" /> {/* Spacer for centering */}
      </div>

      {/* Body */}
      <div className="terminal-body">
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
        <span className="text-[#2997ff] shrink-0">{prompt}</span>
        <span className="text-gray-100">{command}</span>
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
    success: 'text-emerald-400',
    error: 'text-red-400',
    highlight: 'text-[#2997ff] font-medium mt-3 p-3 bg-[#2997ff]/10 rounded-lg',
    default: 'text-gray-400',
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
