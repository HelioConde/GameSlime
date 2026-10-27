"use strict";
const track = document.getElementById("projects-track");
const prev = document.getElementById("prev");
const next = document.getElementById("next");
const position = document.getElementById("carousel-position");
const cards = [...track.querySelectorAll(".project-card")];
const reduced = window.matchMedia("(prefers-reduced-motion: reduce)");

function maxScroll() {
  return Math.max(0, track.scrollWidth - track.clientWidth);
}
function currentIndex() {
  if (cards.length === 0 || maxScroll() <= 2) return 0;
  if (maxScroll() - track.scrollLeft <= 3) return cards.length - 1;
  const trackLeft = track.getBoundingClientRect().left;
  let index = 0;
  let best = Infinity;
  cards.forEach((card, i) => {
    const distance = Math.abs(card.getBoundingClientRect().left - trackLeft);
    if (distance < best) {
      index = i;
      best = distance;
    }
  });
  return index;
}
function updateControls() {
  const canScroll = maxScroll() > 2;
  prev.disabled = !canScroll || track.scrollLeft <= 2;
  next.disabled = !canScroll || maxScroll() - track.scrollLeft <= 2;
  if (position) {
    position.textContent = canScroll
      ? `Projeto ${currentIndex() + 1} de ${cards.length}`
      : `Todos os ${cards.length} projetos estão visíveis`;
  }
}
function goTo(index) {
  if (cards.length === 0 || maxScroll() <= 2) return;
  const clamped = Math.min(cards.length - 1, Math.max(0, index));
  const firstLeft = cards[0].offsetLeft;
  const targetLeft = Math.min(maxScroll(), Math.max(0, cards[clamped].offsetLeft - firstLeft));
  track.scrollTo({ left: targetLeft, behavior: reduced.matches ? "auto" : "smooth" });
  // Scroll events update the controls during motion. This covers engines which
  // only fire one scroll event after the animation finishes.
  window.setTimeout(updateControls, reduced.matches ? 0 : 450);
}
prev.addEventListener("click", () => goTo(currentIndex() - 1));
next.addEventListener("click", () => goTo(currentIndex() + 1));
track.addEventListener("keydown", (event) => {
  // Avoid hijacking arrow keys while a child link or other control has focus.
  if (event.target !== track) return;
  const keys = { ArrowRight: () => goTo(currentIndex() + 1),
    ArrowLeft: () => goTo(currentIndex() - 1),
    Home: () => goTo(0), End: () => goTo(cards.length - 1) };
  if (keys[event.key]) {
    event.preventDefault();
    keys[event.key]();
  }
});
track.addEventListener("scroll", updateControls, { passive: true });
window.addEventListener("resize", updateControls);
updateControls();
