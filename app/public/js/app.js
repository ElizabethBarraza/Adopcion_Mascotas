async function loadPets(){
  const res = await fetch('/api/pets');
  const pets = await res.json();
  const container = document.getElementById('catalog');
  const tpl = document.getElementById('card-template');
  pets.forEach(p => {
    const node = tpl.content.cloneNode(true);
    node.querySelector('.pet-img').src = p.image;
    node.querySelector('.pet-img').alt = p.name;
    node.querySelector('.pet-name').textContent = p.name;
    node.querySelector('.pet-type').textContent = p.type + ' · ' + p.breed;
    node.querySelector('.pet-age').textContent = p.age;
    const btn = node.querySelector('.details');
    btn.addEventListener('click', ()=> openModal(p.id));
    container.appendChild(node);
  });
}

async function openModal(id){
  const res = await fetch('/api/pets/'+id);
  if (!res.ok) return;
  const p = await res.json();
  document.getElementById('modalImg').src = p.image;
  document.getElementById('modalName').textContent = p.name;
  document.getElementById('modalBreed').textContent = p.type + ' · ' + p.breed;
  document.getElementById('modalAge').textContent = p.age;
  document.getElementById('modalDesc').textContent = p.description;
  document.getElementById('modal').classList.remove('hidden');
}

document.getElementById('closeModal').addEventListener('click', ()=> document.getElementById('modal').classList.add('hidden'));
window.addEventListener('click', (e)=> { if (e.target.id === 'modal') document.getElementById('modal').classList.add('hidden');});

loadPets();
