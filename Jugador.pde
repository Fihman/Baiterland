// =====================================================
//  El player
// =====================================================
class Jugador {
  PImage[][][] frames = new PImage[3][4][4];   // [estado][dirección][fotograma]

  float x, y;                 // Posición de los pies (coordenadas)
  float inicioX, inicioY;     // Dónde aparece al empezar
  float velocidad = 260;      // Píxeles del mundo por segundo (con el bienestar completo)
  int direccion = ABAJO;
  int frameActual = 0;
  float tiempoFrame = 0;

  // HitBox
  float mitadAncho = 20;
  float profundidad = 12;

  // Tamaño
  float alturaCelda = 158;
  float anchoCelda = 158 * 128 / 200.0;
  float alturaVisible = 150;  // Altura real del personaje (para el indicador)

  // Tres hojas: normal, cansado (2 vidas) y agotado (1 vida)
  Jugador(float x_, float y_, PImage hoja, PImage hojaCansado, PImage hojaAgotado) {
    x = inicioX = x_;
    y = inicioY = y_;
    cortarFrames(0, hoja);
    cortarFrames(1, hojaCansado);
    cortarFrames(2, hojaAgotado);
  }

  // Corte del spritesheet (Poner los spritesheet)
  void cortarFrames(int estado, PImage hoja) {
    for (int d = 0; d < 4; d++) {
      for (int f = 0; f < 4; f++) {
        frames[estado][d][f] = hoja.get(f * 128, d * 200, 128, 200);
      }
    }
  }

  // Movimiento y animación
  void actualizar(float dt, Habitacion hab, boolean arr, boolean aba, boolean izq, boolean der) {
    float dx = (der ? 1 : 0) - (izq ? 1 : 0);
    float dy = (aba ? 1 : 0) - (arr ? 1 : 0);

    if (dx == 0 && dy == 0) {
      detener();
      return;
    }

    // Dirección y movimiento diagonal
    float mag = sqrt(dx * dx + dy * dy);
    dx /= mag;
    dy /= mag;
    if (abs(dx) >= abs(dy)) direccion = (dx > 0) ? DERECHA : IZQUIERDA;
    else direccion = (dy > 0) ? ABAJO : ARRIBA;

    // Con menos bienestar camina más lento (3 vidas: 100%, 2: 80%, 1: 60%)
    float factor = 0.4 + 0.6 * max(bienestar, 0) / (float) VIDAS;
    float vel = velocidad * factor;

    // Colisiones (un eje a la vez para deslizar por los bordes)
    float nx = x + dx * vel * dt;
    if (!hab.colisiona(nx, y, mitadAncho, profundidad)) x = nx;
    float ny = y + dy * vel * dt;
    if (!hab.colisiona(x, ny, mitadAncho, profundidad)) y = ny;

    // Animación (los pasos también se hacen más lentos)
    tiempoFrame += dt;
    if (tiempoFrame > 0.13 / factor) {
      tiempoFrame = 0;
      frameActual = (frameActual + 1) % 4;
    }
  }

  void detener() {
    frameActual = 0;
    tiempoFrame = 0;
  }

  // Vuelve al punto de inicio
  void reiniciar() {
    x = inicioX;
    y = inicioY;
    direccion = ABAJO;
    detener();
  }

  // (sombra + sprite)
  void dibujar(Habitacion hab) {
    float e  = hab.escala;
    float px = hab.sx(x);
    float py = hab.sy(y);

    noStroke();
    fill(0, 80);
    ellipse(px, py - 2 * e, 46 * e, 14 * e);

    // El aspecto cambia con el bienestar (3 vidas: normal, 2: cansado, 1: agotado)
    int estado = constrain(VIDAS - bienestar, 0, 2);
    image(frames[estado][direccion][frameActual],
          px - anchoCelda * e / 2, py - alturaCelda * e,
          anchoCelda * e, alturaCelda * e);
  }
}
