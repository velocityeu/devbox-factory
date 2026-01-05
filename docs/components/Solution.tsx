'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const beforeItems = [
  '2+ days wrestling with setup',
  'Hours debugging PATH issues',
  'Endless Stack Overflow tabs',
  '3 attempts to get Docker running',
  'Frustration and lost motivation',
  'Inconsistent environments across machines',
  'Hope that it works next time',
]

const afterItems = [
  { text: '2 minutes to start coding', highlight: true },
  { text: 'Zero configuration needed', highlight: true },
  { text: 'One command, everything works', highlight: true },
  { text: 'Pre-tested tool combinations', highlight: true },
  { text: 'Excitement preserved', highlight: true },
  { text: 'Identical environments guaranteed', highlight: true },
  { text: 'Certainty it works every time', highlight: true },
]

const valueProps = [
  { icon: '&#128176;', title: 'Save $500+ Per Developer', description: '2 days of setup time = real money. Multiply by your team size.' },
  { icon: '&#129504;', title: 'Preserve Your Energy', description: 'Spend your mental energy on building, not battling your tools.' },
  { icon: '&#9889;', title: 'Immediate Productivity', description: 'From zero to vibe coding in the time it takes to make coffee.' },
]

export default function Solution() {
  return (
    <section id="solution" className="py-20 md:py-32 px-4 bg-background-secondary/50">
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
            The Solution
          </span>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold mb-4">
            What If Setup Just... <span className="gradient-text">Worked?</span>
          </h2>
          <p className="text-zinc-400 max-w-xl mx-auto">
            DevBox Factory is the missing piece. One command gives you a battle-tested,
            production-ready dev environment with everything pre-configured correctly.
          </p>
        </motion.div>

        {/* Comparison */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-16 relative">
          {/* Before */}
          <Card hover={false} className="border-red-500/30">
            <div className="flex items-center gap-3 mb-6">
              <span className="text-2xl">&#10060;</span>
              <h3 className="text-xl font-bold">Without DevBox Factory</h3>
            </div>
            <ul className="space-y-3 mb-6">
              {beforeItems.map((item) => (
                <li key={item} className="flex items-center gap-3 py-2 border-b border-white/5 text-zinc-400">
                  <span className="text-white font-medium">{item.split(' ')[0]}</span>
                  <span>{item.split(' ').slice(1).join(' ')}</span>
                </li>
              ))}
            </ul>
            <div className="flex items-center gap-3 p-4 bg-red-500/10 rounded-xl">
              <span className="text-2xl">&#128553;</span>
              <span className="font-semibold">Still debugging setup at midnight</span>
            </div>
          </Card>

          {/* VS Badge - Desktop */}
          <div className="hidden lg:flex absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-10">
            <span className="px-4 py-2 bg-gradient-primary rounded-full font-extrabold text-sm">VS</span>
          </div>

          {/* VS Badge - Mobile */}
          <div className="flex lg:hidden justify-center -my-3 z-10">
            <span className="px-4 py-2 bg-gradient-primary rounded-full font-extrabold text-sm">VS</span>
          </div>

          {/* After */}
          <Card hover={false} className="border-green-500/30 bg-gradient-to-br from-green-500/5 to-transparent">
            <div className="flex items-center gap-3 mb-6">
              <span className="text-2xl">&#9989;</span>
              <h3 className="text-xl font-bold">With DevBox Factory</h3>
            </div>
            <ul className="space-y-3 mb-6">
              {afterItems.map((item) => (
                <li key={item.text} className="flex items-center gap-3 py-2 border-b border-white/5 text-zinc-400">
                  <span className={item.highlight ? 'text-green-400 font-medium' : 'text-white font-medium'}>
                    {item.text.split(' ')[0]}
                  </span>
                  <span>{item.text.split(' ').slice(1).join(' ')}</span>
                </li>
              ))}
            </ul>
            <div className="flex items-center gap-3 p-4 bg-green-500/10 rounded-xl">
              <span className="text-2xl">&#128640;</span>
              <span className="font-semibold">Already shipping features</span>
            </div>
          </Card>
        </div>

        {/* Value Props */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
          {valueProps.map((prop, index) => (
            <Card key={prop.title} delay={index * 0.1} className="text-center">
              <div
                className="text-4xl mb-4"
                dangerouslySetInnerHTML={{ __html: prop.icon }}
              />
              <h4 className="text-lg font-bold mb-2">{prop.title}</h4>
              <p className="text-zinc-400 text-sm">{prop.description}</p>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
