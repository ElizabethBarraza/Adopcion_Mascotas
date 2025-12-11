const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 8080;
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let pets = [
  { id: 'p1', name: 'Luna', type: 'Gata', age: '2 años', breed: 'Siames', description: 'Mimada, tranquila y cariñosa.', image: '/images/cat1.jpeg' },
  { id: 'p2', name: 'Rocco', type: 'Perro', age: '3 años', breed: 'Labrador', description: 'Activo y juguetón, ideal para familia.', image: '/images/dog1.jpg' },
  { id: 'p3', name: 'Mimi', type: 'Gata', age: '1 año', breed: 'Europea', description: 'Curiosa y juguetona, le gusta trepar.', image: '/images/cat2.jpeg' },
  { id: 'p4', name: 'Toby', type: 'Perro', age: '4 años', breed: 'Beagle', description: 'Calmado, buen compañero para paseos cortos.', image: '/images/dog2.jpeg' }
];

app.get('/api/pets', (req, res) => res.json(pets));
app.get('/api/pets/:id', (req, res) => {
  const p = pets.find(x => x.id === req.params.id);
  if (!p) return res.status(404).json({error:'Not found'});
  res.json(p);
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
