import Navbar from '@/components/Navbar'
import Hero from '@/components/Hero'
import Problem from '@/components/Problem'
import Solution from '@/components/Solution'
import Features from '@/components/Features'
import Profiles from '@/components/Profiles'
import Demo from '@/components/Demo'
import QuickStart from '@/components/QuickStart'
import Testimonials from '@/components/Testimonials'
import About from '@/components/About'
import FAQ from '@/components/FAQ'
import Footer from '@/components/Footer'

export default function Home() {
  return (
    <main className="relative">
      <Navbar />
      <Hero />
      <Problem />
      <Solution />
      <Features />
      <Profiles />
      <Demo />
      <QuickStart />
      <Testimonials />
      <About />
      <FAQ />
      <Footer />
    </main>
  )
}
