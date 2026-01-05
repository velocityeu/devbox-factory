'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import Terminal from './ui/Terminal'

const steps = [
  {
    number: 1,
    title: 'Run One Command',
    description: 'Copy, paste, press Enter. That\'s it.',
  },
  {
    number: 2,
    title: 'Pick Your Profile',
    description: 'Interactive menu. No config files to edit.',
  },
  {
    number: 3,
    title: 'Grab Coffee',
    description: 'Watch the progress bars while tools install automatically.',
  },
  {
    number: 4,
    title: 'Start Building',
    description: 'Everything works. Claude Code is ready. Ship something cool.',
  },
]

const terminalContent: Record<number, string> = {
  1: `PS C:\\> irm devbox.run | iex

Downloading DevBox Factory...
████████████████████████████████ 100%

✓ Downloaded successfully!
✓ Verifying checksums...
✓ Extracting files...

Starting interactive installer...`,
  2: `╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     ⚡ DevBox Factory v3.5.2                             ║
║     One command. Perfect dev environment. Every time.     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

? Select installation profile:

  ❯ 🤖 AI Coder      - Claude Code, Cursor, VS Code + AI
    🌐 Web Developer - Node.js, Python, Docker, Databases
    ☁️  Azure Developer - Azure CLI, .NET, Terraform
    🚀 Full Stack    - Everything included
    🎯 Minimal       - Git, Terminal, VS Code only

  ↑/↓: Navigate  Enter: Select  Esc: Cancel`,
  3: `Installing AI Coder profile...

✓ Installing Git for Windows...
✓ Installing Windows Terminal...
✓ Installing VS Code...
→ Installing Claude Code CLI...
  ████████████████████░░░░░░░░░░░░ 65%

Estimated time remaining: 8 minutes
☕ Perfect time for that coffee...`,
  4: `╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     ✨ Installation Complete!                            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

✓ Git configured and ready
✓ Claude Code CLI installed (claude --version: 1.0.17)
✓ Cursor IDE installed
✓ VS Code + AI extensions configured
✓ Node.js 22 (via NVM) ready
✓ Python 3.12 installed

→ Run claude to start vibe coding!

Total time: 14 minutes 32 seconds`,
}

export default function Demo() {
  const [activeStep, setActiveStep] = useState(1)

  return (
    <section id="demo" className="py-20 md:py-32 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-12 md:mb-16"
        >
          <span className="inline-block px-4 py-1.5 mb-4 bg-white/5 border border-white/10 rounded-full text-sm text-accent-primary">
            See It In Action
          </span>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold">
            From Zero to <span className="gradient-text">Vibe Coding</span>
          </h2>
        </motion.div>

        <div className="grid lg:grid-cols-[300px_1fr] gap-6 lg:gap-10">
          {/* Steps - Horizontal scroll on mobile */}
          <div className="flex lg:flex-col gap-3 overflow-x-auto pb-4 lg:pb-0 -mx-4 px-4 lg:mx-0 lg:px-0">
            {steps.map((step) => (
              <button
                key={step.number}
                onClick={() => setActiveStep(step.number)}
                className={`
                  flex items-start gap-4 p-4 min-w-[200px] lg:min-w-0
                  rounded-xl border transition-all duration-300 text-left
                  ${activeStep === step.number
                    ? 'bg-accent-primary/10 border-accent-primary'
                    : 'bg-white/5 border-white/10 hover:border-accent-primary/50'
                  }
                `}
              >
                <span className="w-8 h-8 flex items-center justify-center bg-gradient-primary rounded-full text-sm font-bold shrink-0">
                  {step.number}
                </span>
                <div>
                  <h4 className="font-semibold mb-1">{step.title}</h4>
                  <p className="text-sm text-zinc-400">{step.description}</p>
                </div>
              </button>
            ))}
          </div>

          {/* Terminal */}
          <motion.div
            key={activeStep}
            initial={{ opacity: 0, x: 10 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.3 }}
          >
            <Terminal title="DevBox Factory" className="h-full">
              <pre className="text-xs sm:text-sm text-zinc-400 whitespace-pre-wrap leading-relaxed">
                {terminalContent[activeStep]}
              </pre>
            </Terminal>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
