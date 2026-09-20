import { ArrowUpRight, Eye } from 'lucide-react'
import { portfolioItems } from '../../data/catalog'

export default function Portfolio({ onOpen }) {
  const [style, setStyle] = React.useState('Tous')
  const [artist, setArtist] = React.useState('Tous')
  const filtered = portfolioItems.filter((item) => (style === 'Tous' || item.style === style) && (artist === 'Tous' || item.artist === artist))
  return <section id="portfolio" className="portfolio tattoo-section">
    <div className="section-heading"><div><span className="eyebrow orange">L'ARCHIVE</span><h2>Travaux récents</h2></div><button className="text-link light">Voir tout <ArrowUpRight size={16}/></button></div>
    <div className="filters" aria-label="Filtres du portfolio"><span>Style</span>{['Tous', 'Blackwork', 'Fine line', 'Ornemental'].map((item) => <button className={style === item ? 'selected' : ''} key={item} onClick={() => setStyle(item)}>{item}</button>)}<span className="filter-divider"/><span>Artiste</span>{['Tous', 'Jiji', 'Malo', 'Naya'].map((item) => <button className={artist === item ? 'selected' : ''} key={item} onClick={() => setArtist(item)}>{item}</button>)}</div>
    {filtered.length ? <div className="portfolio-grid">{filtered.map((item, index) => <button className={`portfolio-card card-${index % 3}`} key={item.title} onClick={() => onOpen(item)} aria-label={`Voir ${item.title}`}><img src={item.image} alt={item.title}/><span className="view-icon"><Eye size={17}/></span><div className="portfolio-meta"><span>{item.style}</span><strong>{item.title}</strong><small>{item.artist}</small></div></button>)}</div> : <p className="empty-state">Aucune pièce ne correspond à ces filtres.</p>}
  </section>
}

import React from 'react'
