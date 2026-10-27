"use strict";
const track=document.getElementById("projects-track");
const prev=document.getElementById("prev");
const next=document.getElementById("next");
const cards=[...track.querySelectorAll(".project-card")];
const reduced=window.matchMedia("(prefers-reduced-motion: reduce)");
function currentIndex(){const x=track.getBoundingClientRect().left;let index=0,best=Infinity;cards.forEach((card,i)=>{const d=Math.abs(card.getBoundingClientRect().left-x);if(d<best){best=d;index=i}});return index}
function updateControls(){const width=track.clientWidth;const canScroll=track.scrollWidth>width+2;const end=track.scrollWidth-track.scrollLeft-width;prev.disabled=!canScroll||track.scrollLeft<=2;next.disabled=!canScroll||end<=2}
function move(dir){const i=Math.max(0,Math.min(cards.length-1,currentIndex()+dir));cards[i].scrollIntoView({behavior:reduced.matches?"instant":"smooth",block:"nearest",inline:"start"});window.setTimeout(updateControls,reduced.matches?0:350)}
prev.addEventListener("click",()=>move(-1));next.addEventListener("click",()=>move(1));
track.addEventListener("keydown",e=>{if(e.key==="ArrowRight"||e.key==="ArrowLeft"){e.preventDefault();move(e.key==="ArrowRight"?1:-1)}});
track.addEventListener("scroll",updateControls,{passive:true});
window.addEventListener("resize",updateControls);
updateControls();
