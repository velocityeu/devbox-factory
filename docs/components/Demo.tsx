'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import Terminal from './ui/Terminal'

const steps = [
  { num: 1, title: 'Run One Command', desc: 'Copy, paste, enter.' },
  { num: 2, title: 'Pick Your Profile', desc: 'Interactive menu.' },
  { num: 3, title: 'Grab Coffee', desc: 'Watch progress bars.' },
  { num: 4, title: 'Start Building', desc: 'Everything works.' },
]

const terminalContent: Record<number, string> = {
  1: `PS C:\\> irm devbox.run | iex

Downloading DevBox Factory...
████████████████████████████████ 100%

✓ Downloaded successfully
✓ Verifying checksums
✓ Extracting files

Starting installer...`,
  2: `╔═══════════════════════════════════════════════╗
║  ⚡ DevBox Factory v3.5.2                      ║
║  One command. Perfect dev environment.         ║
╚═══════════════════════════════════════════════╝

? Select profile:

  ❯ 🤖 AI Coder     - Claude, Cursor, VS Code
    🌐 Web Dev      - Node, Python, Docker
    ☁️  Azure        - CLI, .NET, Terraform
    🚀 Full Stack   - Everything
    🎯 Minimal      - Just essentials`,
  3: `Installing AI Coder profile...

✓ Git for Windows
✓ Windows Terminal
✓ VS Code
→ Claude Code CLI...
  ████████████████████░░░░░░░░ 65%

Estimated: 8 minutes remaining`,
  4: `╔═══════════════════════════════════════════════╗
║  ✨ Installation Complete!                     ║
╚═══════════════════════════════════════════════╝

✓ Git configured
✓ Claude Code CLI (v1.0.17)
✓ Cursor IDE
✓ VS Code + extensions
✓ Node.js 22 (NVM)
✓ Python 3.12

→ Run 'claude' to start coding!`,
}

export default function Demo() {
  const [active, setActive] = useState(1)

  return (
    <section id="demo" className="py-24 md:py-32 px-5">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">See It In Action</span>
          <h2 className="text-display text-primary">
            Zero to <span className="gradient-text">coding</span>
          </h2>
        </motion.div>

        <div className="grid lg:grid-cols-[280px_1fr] gap-6">
          {/* Steps */}
          <div className="flex lg:flex-col gap-2 overflow-x-auto pb-4 lg:pb-0 -mx-5 px-5 lg:mx-0 lg:px-0">
            {steps.map((step) => (
              <button
                key={step.num}
                onClick={() => setActive(step.num)}
                className={`
                  flex items-center gap-3 p-4 min-w-[180px] lg:min-w-0
                  rounded-xl border text-left transition-all duration-200
                  ${active === step.num
                    ? 'bg-[var(--color-accent)]/5 border-[var(--color-accent)]/30'
                    : 'border-[var(--color-border-light)] hover:border-[var(--color-accent)]/20'
                  }
                `}
              >
                <span className={`
                  w-8 h-8 flex items-center justify-center rounded-full text-sm font-medium shrink-0
                  ${active === step.num ? 'bg-[var(--color-accent)] text-white' : 'bg-[var(--color-bg-secondary)] text-secondary'}
                `}>
                  {step.num}
                </span>
                <div>
                  <div className="font-medium text-primary text-sm">{step.title}</div>
                  <div className="text-xs text-tertiary">{step.desc}</div>
                </div>
              </button>
            ))}
          </div>

          {/* Terminal */}
          <motion.div
            key={active}
            initial={{ opacity: 0, x: 8 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.2 }}
          >
            <Terminal title="DevBox Factory">
              <pre className="text-xs sm:text-sm text-gray-400 whitespace-pre-wrap leading-relaxed">
                {terminalContent[active]}
              </pre>
            </Terminal>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
