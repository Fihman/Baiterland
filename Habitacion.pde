// =====================================================
//  El cuarto bb (y la pantalla del PC)
// =====================================================
class Habitacion {
  PImage imagen, imagenEscalada;
  PGraphics fondoDifuso;
  float ancho, alto;               // Tamaño de la pantalla
  float escala, offX, offY;

  // Pantalla del PC
  PImage pcEscalada;
  float pcEsc, pcX, pcY;

  // Límites del suelo
  float minX = 20, maxX = 896, minY = 330, maxY = 915;

  // Hitboxes (x, y, ancho, alto)
  float[][] obstaculos = {
    {6, 217, 238, 95},     // Escritorio (parte superior)
    {6, 312, 153, 60},     // Escritorio (diagonal)
    {6, 372, 73, 115},     // Escritorio (pata izquierda)
    {244, 217, 181, 150},  // Escritorio (lado derecho)
    {144, 327, 95, 150},   // Silla
    {376, 227, 160, 117},  // Repisa central
    {844, 242, 70, 285},   // Estante derecho
    {6, 642, 93, 110},     // Mesa de noche
    {4, 712, 285, 215}     // Cama
  };

  // PC (zona para usarlo) y logos de Instagram en la pantalla del PC
  float[] zonaPC = {60, 330, 340, 240};
  float[][] iconosInstagram = {
    {190, 196, 132, 122},  // Escritorio
    {700, 896, 52, 52}     // Barra de tareas
  };

  boolean depurar = false;

  Habitacion(PImage img, PImage pc) {
    imagen = img;
    ancho = img.width;
    alto = img.height;

    // Ajuste de la imagen cuadrada a la nueva resolución
    escala = min(width / ancho, height / alto);
    offX = (width - ancho * escala) / 2;
    offY = (height - alto * escala) / 2;
    imagenEscalada = imagen.get();
    imagenEscalada.resize(round(ancho * escala), round(alto * escala));
    construirFondoDifuso();

    // Ajuste de la pantalla del PC
    pcEsc = min(width / (float) pc.width, height / (float) pc.height);
    pcX = (width - pc.width * pcEsc) / 2;
    pcY = (height - pc.height * pcEsc) / 2;
    pcEscalada = pc.get();
    pcEscalada.resize(round(pc.width * pcEsc), round(pc.height * pcEsc));
  }

  // Los laterales
  void construirFondoDifuso() {
    PImage pequena = imagen.get();
    pequena.resize(48, 0);
    pequena.filter(BLUR, 2);
    fondoDifuso = createGraphics(width, height);
    fondoDifuso.beginDraw();
    fondoDifuso.image(pequena, 0, 0, width, height);
    fondoDifuso.noStroke();
    fondoDifuso.fill(0, 150);
    fondoDifuso.rect(0, 0, width, height);
    fondoDifuso.endDraw();
  }

  // Conversión mundo a pantalla
  float sx(float wx) { return offX + wx * escala; }
  float sy(float wy) { return offY + wy * escala; }

  // Rectángulos (arreglos {x, y, ancho, alto})
  boolean chocan(float[] r, float x, float y, float w, float h) {
    return r[0] < x + w && r[0] + r[2] > x && r[1] < y + h && r[1] + r[3] > y;
  }

  boolean dentro(float[] r, float px, float py) {
    return px >= r[0] && px <= r[0] + r[2] && py >= r[1] && py <= r[1] + r[3];
  }

  // Hitbox del personaje (pies)
  boolean colisiona(float px, float py, float mitad, float prof) {
    if (px - mitad < minX || px + mitad > maxX || py - prof < minY || py > maxY) return true;
    for (int i = 0; i < obstaculos.length; i++) {
      if (chocan(obstaculos[i], px - mitad, py - prof, mitad * 2, prof)) return true;
    }
    return false;
  }

  // Zona del PC (true si el personaje está dentro)
  boolean enZonaPC(Jugador j) {
    return dentro(zonaPC, j.x, j.y);
  }

  // Dibujo completo de la habitación
  void dibujar(Jugador j) {
    image(fondoDifuso, 0, 0);
    image(imagenEscalada, offX, offY);

    j.dibujar(this);

    // Indicador sobre la cabeza del personaje
    if (enZonaPC(j) && !fundiendo) {
      float cx = sx(j.x);
      float cabeza = sy(j.y - j.alturaVisible) - 14 + sin(millis() * 0.006) * 5;
      dibujarBurbujaTecla("E", "Usar el computador", cx, cabeza, true);
    }

    if (depurar) dibujarDepuracion(j);
  }

  // Etapa de depuración (tecla H): muestra obstáculos y zonas
  void dibujarDepuracion(Jugador j) {
    strokeWeight(2);
    noFill();
    stroke(255, 60, 60);
    for (int i = 0; i < obstaculos.length; i++) {
      rect(sx(obstaculos[i][0]), sy(obstaculos[i][1]), obstaculos[i][2] * escala, obstaculos[i][3] * escala);
    }
    stroke(60, 255, 120);
    rect(sx(zonaPC[0]), sy(zonaPC[1]), zonaPC[2] * escala, zonaPC[3] * escala);
    stroke(255, 255, 0);
    rect(sx(j.x - j.mitadAncho), sy(j.y - j.profundidad), j.mitadAncho * 2 * escala, j.profundidad * escala);
    stroke(60, 120, 255);
    rect(sx(minX), sy(minY), (maxX - minX) * escala, (maxY - minY) * escala);
    strokeWeight(1);
  }

  // =====================================================
  //  Pantalla del PC
  // =====================================================

  // Logo de Instagram bajo el mouse (-1 si ninguno)
  int iconoBajoMouse() {
    float px = (mouseX - pcX) / pcEsc;
    float py = (mouseY - pcY) / pcEsc;
    for (int i = 0; i < iconosInstagram.length; i++) {
      if (dentro(iconosInstagram[i], px, py)) return i;
    }
    return -1;
  }

  // Clic en el logo de Instagram
  void clicPC() {
    if (iconoBajoMouse() >= 0 && !fundiendo) irA(ESTADO_INSTAGRAM);
  }

  void dibujarPC() {
    background(10, 14, 25);
    image(pcEscalada, pcX, pcY);

    // Reloj de la barra de tareas (el mismo de los mensajes de Instagram)
    fuente(false, 21 * pcEsc);
    textAlign(CENTER, CENTER);
    fill(235, 240, 245);
    text(horaJuego(segundosJuego), pcX + 1514 * pcEsc, pcY + 913 * pcEsc);
    text(fechaJuego(segundosJuego), pcX + 1514 * pcEsc, pcY + 941 * pcEsc);

    // Resaltado al pasar el mouse
    int ic = iconoBajoMouse();
    if (ic >= 0 && !fundiendo) {
      float[] a = iconosInstagram[ic];
      noStroke();
      fill(255, 255, 255, 60);
      rect(pcX + a[0] * pcEsc, pcY + a[1] * pcEsc, a[2] * pcEsc, a[3] * pcEsc, 10);
      cursor(HAND);
    }

    // Indicador para salir
    if (!fundiendo) {
      dibujarBurbujaTecla("ESC", "Salir del computador", width / 2, height * 0.07, false);
    }
  }
}
