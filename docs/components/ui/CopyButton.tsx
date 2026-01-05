'use client'

import { useState } from 'react'

interface CopyButtonProps {
  text: string
  className?: string
}

export default function CopyButton({ text, className = '' }: CopyButtonProps) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      // Fallback for older browsers
      const textArea = document.createElement('textarea')
      textArea.value = text
      textArea.style.position = 'fixed'
      textArea.style.opacity = '0'
      document.body.appendChild(textArea)
      textArea.select()
      document.execCommand('copy')
      document.body.removeChild(textArea)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  return (
    <button
      onClick={handleCopy}
      className={`
        flex items-center gap-2 px-4 py-2 min-h-[44px]
        bg-background-tertiary border border-white/10 rounded-lg
        text-sm text-zinc-400 font-medium
        transition-all duration-200
        hover:bg-accent-primary hover:text-white hover:border-accent-primary
        active:scale-95
        ${copied ? 'bg-green-500 border-green-500 text-white' : ''}
        ${className}
      `}
    >
      {copied ? (
        <>
          <span>&#10003;</span>
          <span>Copied!</span>
        </>
      ) : (
        <>
          <span>&#128203;</span>
          <span>Copy</span>
        </>
      )}
    </button>
  )
}
