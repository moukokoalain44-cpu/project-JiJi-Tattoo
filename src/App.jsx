import React, { useMemo, useState } from 'react'
import { ArrowUpRight, Instagram, Quote, ShieldCheck } from 'lucide-react'
import Navigation from './components/navigation/Navigation'
import Portfolio from './components/gallery/Portfolio'
import Shop from './components/shop/Shop'
import BookingModal from './components/booking/BookingModal'

export default function App() {
  const [universe, setUniverse] = useState('tattoo')
  const [modal, setModal] = useState(null)
  const [mobileOpen, setMobileOpen] = useState(false)
  const [lightbox, setLightbox] = useState(null)
  const [cart, setCart] = useState([])
  const total = useMemo(() => cart.reduce((sum, item) => sum + item.price, 0), [cart])
  const scrollTo = (id) => { setMobileOpen(false); document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' }) }
  const addToCart = (item) => setCart((items) => [...items, item])

  return <main className={`site theme-${universe}`}>
    <Navigation activeUniverse={universe} setUniverse={setUniverse} cartCount={cart.length} onBooking={() => setModal('booking')} onCart={() => setModal('cart')} mobileOpen={mobileOpen} setMobileOpen={setMobileOpen} scrollTo={scrollTo}/>
    <section id="home" className="hero tattoo-section"><div className="hero-image"/><div className="hero-overlay"/><div className="hero-content"><p className="eyebrow">PARIS · 11e — TATTOO / PIERCING / CARE</p><h1>Art that lives<br/><em>under</em> your skin.</h1><p className="hero-copy">Un studio indépendant où le geste rencontre l'intention. Des pièces pensées pour durer, dans un espace qui vous ressemble.</p><div className="hero-actions"><button className="button button-accent" onClick={() => setModal('booking')}>Réserver une session <ArrowUpRight size={17}/></button><button className="text-link light" onClick={() => scrollTo('portfolio')}>Découvrir le travail <ArrowUpRight size={17}/></button></div></div><div className="hero-footer"><span>Scroll to explore</span><span className="line"/><span>01 / 04</span></div></section>
    <section id="studio" className="manifesto tattoo-section"><div><span className="eyebrow orange">NOTRE MANIÈRE DE FAIRE</span><h2>La peau comme<br/><em>terrain d'expression.</em></h2></div><div className="manifesto-copy"><p>Chez Jiji, chaque tatouage commence par une conversation. Nous créons des pièces singulières, entre lignes précises, noirs profonds et mouvements organiques.</p><button className="text-link" onClick={() => setModal('booking')}>Rencontrer l'équipe <ArrowUpRight size={16}/></button></div></section>
    <Portfolio onOpen={setLightbox}/>
    <section id="piercing" className="piercing-section"><div className="piercing-intro"><div><span className="eyebrow forest">PIERCING · JIJI STUDIO</span><h2>Precision.<br/><em>Peace of mind.</em></h2></div><p>Le piercing comme un rituel calme et précis. Bijoux sélectionnés, gestes maîtrisés et accompagnement sur mesure, de la première idée au suivi de cicatrisation.</p></div><div className="piercing-grid"><div className="piercing-photo"><img src="https://images.unsplash.com/photo-1619451334792-150fd785ee74?auto=format&fit=crop&w=1200&q=85" alt="Bijoux de piercing"/><span>01 — L'atelier</span></div><div className="care-card"><ShieldCheck size={27}/><span className="eyebrow forest">NOTRE ENGAGEMENT</span><h3>Clean by design.</h3><p>Un environnement stérile, des aiguilles à usage unique et des bijoux en titane ASTM-F136 ou or 14/18 carats.</p><button className="outline-button" onClick={() => setModal('booking')}>Voir les prestations <ArrowUpRight size={15}/></button></div></div><div className="material-row"><span>Matériaux certifiés</span><span>Titane ASTM-F136</span><span>Or 14 / 18 carats</span><span>Suivi inclus</span></div></section>
    <Shop onAdd={addToCart}/>
    <section className="reviews tattoo-section"><div className="review-quote"><Quote size={34}/><blockquote>“Jiji a transformé une cicatrice en quelque chose que je regarde avec fierté chaque jour.”</blockquote><div className="reviewer"><span className="avatar">C</span><span><strong>Camille R.</strong><small>Pièce custom · Paris</small></span><span className="stars">★★★★★</span></div></div><div className="review-side"><span className="eyebrow orange">LA PAROLE AUX CLIENT·ES</span><h3>Ce sont vos histoires qui font le studio.</h3><button className="outline-button light-outline" onClick={() => setModal('review')}>Partager mon expérience <ArrowUpRight size={15}/></button></div></section>
    <section className="booking-banner"><div><span className="eyebrow">UN PROJET EN TÊTE ?</span><h2>Let's make it<br/><em>personal.</em></h2></div><button className="button button-accent" onClick={() => setModal('quote')}>Demander un devis <ArrowUpRight size={17}/></button></section>
    <footer><div className="brand"><span>JIJI</span><small>TATTOO STUDIO</small></div><p>Art, intention & care.<br/>Paris 11e — Sur rendez-vous.</p><div className="footer-links"><span>Instagram <Instagram size={15}/></span><span>© 2024 Jiji Tattoo</span></div></footer>
    {modal && <BookingModal type={modal} close={() => setModal(null)} cart={cart} total={total} setCart={setCart} onSubmitted={() => setModal(null)}/>}
    {lightbox && <div className="lightbox" role="dialog" aria-label={`Détail de ${lightbox.title}`} onClick={() => setLightbox(null)}><button onClick={() => setLightbox(null)} aria-label="Fermer">×</button><img src={lightbox.image} alt={lightbox.title}/><div><span>{lightbox.style} · {lightbox.artist}</span><h3>{lightbox.title}</h3></div></div>}
  </main>
}
