import { ArrowUpRight, Menu, ShoppingBag, X } from 'lucide-react'

export default function Navigation({ activeUniverse, setUniverse, cartCount, onBooking, onCart, mobileOpen, setMobileOpen, scrollTo }) {
  const go = (universe, id) => {
    setUniverse(universe)
    scrollTo(id)
  }
  return <>
    <header className={`navbar navbar-${activeUniverse}`} aria-label="Navigation principale">
      <button className="brand" onClick={() => go('tattoo', 'home')} aria-label="Retour à l'accueil"><span>JIJI</span><small>TATTOO STUDIO</small></button>
      <nav className="desktop-nav">
        <button onClick={() => go('tattoo', 'studio')}>Le studio</button>
        <button onClick={() => go('tattoo', 'portfolio')}>Portfolio</button>
        <button onClick={() => go('piercing', 'piercing')}>Piercing</button>
        <button onClick={() => go('skincare', 'shop')}>Skincare</button>
      </nav>
      <div className="nav-actions">
        <button className="cart-button" onClick={onCart} aria-label={`Panier, ${cartCount} article(s)`}><ShoppingBag size={17}/><span>{cartCount}</span></button>
        <button className="button button-small" onClick={onBooking}>Prendre RDV <ArrowUpRight size={15}/></button>
        <button className="mobile-trigger" onClick={() => setMobileOpen(true)} aria-label="Ouvrir le menu"><Menu size={21}/></button>
      </div>
    </header>
    {mobileOpen && <div className="mobile-menu" role="dialog" aria-label="Menu mobile">
      <button className="close-menu" onClick={() => setMobileOpen(false)} aria-label="Fermer"><X/></button>
      <span className="eyebrow">JIJI TATTOO STUDIO</span>
      <button onClick={() => go('tattoo', 'studio')}>Le studio</button>
      <button onClick={() => go('tattoo', 'portfolio')}>Portfolio</button>
      <button onClick={() => go('piercing', 'piercing')}>Piercing</button>
      <button onClick={() => go('skincare', 'shop')}>Skincare</button>
      <button className="button" onClick={() => { setMobileOpen(false); onBooking() }}>Prendre rendez-vous <ArrowUpRight size={16}/></button>
    </div>}
  </>
}
