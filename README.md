# Adopción de Mascotas (Catálogo básico)

Proyecto para la práctica RA Unidad IV — tema: Adopción de Mascotas.

Funcionalidad:
- Listar mascotas disponibles.
- Ver detalles de cada mascota en un modal.
- UI simple y agradable, responsive.

Ejecutar localmente:
cd app
npm install
npm start
# abrir http://mascotas-alb-1019600993.us-east-1.elb.amazonaws.com/

Docker:
docker build -t elibarraza/adopcion-mascotas:1.0 ./app
docker run -p 8080:8080 elibarraza/adopcion-mascotas:1.0

Infraestructura e IaC:
La carpeta infra/ incluye un ejemplo de Terraform (ajustar variables antes de aplicar).

CI/CD:
Incluye workflow básico para GitHub Actions en .github/workflows/main.yml. Agrega secrets DOCKERHUB_USERNAME y DOCKERHUB_TOKEN.

**Clonar el repositorio:** `git clone https://github.com/ElizabethBarraza/Adopcion_Mascotas.git`
