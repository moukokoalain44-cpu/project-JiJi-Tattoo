import React, { useMemo, useState } from 'react'
import { Plus, Sparkles } from 'lucide-react'
import { products } from '../../data/catalog'

export default function Shop({ onAdd }) {
  const [concern, setConcern] = useState('Tous les essentiels')
  const concerns = ['Tous les essentiels', 'Après-tatouage', 'Hydratation', 'Peau sensible']
  const visible = useMemo(() => concern === 'Tous les essentiels' ? products : products.filter((product) => concern === 'Après-tatouage' ? product.id !== 'cleanse' : true), [concern])
  return <section id="shop" className="shop-section">
    <div className="shop-heading"><div><span className="eyebrow lavender">Jiji skin / care</span><h2>Take care of<br/><em>your canvas.</em></h2></div><p>Des formules essentielles, pensées pour apaiser et révéler votre peau — avant, pendant et après le tatouage.</p></div>
    <div className="shop-layout"><aside><span className="eyebrow">SHOP BY CONCERN</span>{concerns.map((item, index) => <button className={concern === item ? 'active' : ''} key={item} onClick={() => setConcern(item)}>{item}<span>{index === 0 ? '04' : '03'}</span></button>)}<div className="shop-note"><Sparkles size={18}/><p>Livraison offerte<br/>dès 60€ en France</p></div></aside>
      <div className="product-grid">{visible.map((product) => <article className="product-card" key={product.id}><div className={`product-image ${product.color}`}><img src={product.image} alt={product.name}/><button onClick={() => onAdd(product)} aria-label={`Ajouter ${product.name} au panier`}><Plus size={18}/></button></div><div className="product-info"><div><span>{product.type}</span><h3>{product.name}</h3></div><strong>{product.price}€</strong></div></article>)}</div>
    </div>
  </section>
}
