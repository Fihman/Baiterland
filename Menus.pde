// =====================================================
//  Menú vertical con el diseño neón 
//  (inicio, pausa y fin del juego usan el mismo)
// =====================================================
class MenuNeon {
  int n, seleccion = 0;
  PImage[] etiquetas;
  float[] t, bx, by, bw, bh;   // Animación (0 = normal, 1 = seleccionado) y posición de cada botón
  float yInicio, anchoNormal, anchoGrande, altoNormal, altoGrande;
  float separacion = 8, altoTotal, escalaBase;

  String aviso = "";
  float tiempoAviso = 0;

  // Nombres de las etiquetas en data/ui (txt_<nombre>.png)
  MenuNeon(String[] archivos, float yInicio_, float anchoNormal_, float anchoGrande_) {
    n = archivos.length;
    etiquetas = new PImage[n];
    t  = new float[n];
    bx = new float[n];
    by = new float[n];
    bw = new float[n];
    bh = new float[n];
    yInicio = yInicio_;
    anchoNormal = anchoNormal_;
    anchoGrande = anchoGrande_;
    altoNormal = marcoNormal[0].height;
    altoGrande = marcoGrande[0].height;

    float maxAncho = 0;
    for (int i = 0; i < n; i++) {
      etiquetas[i] = loadImage("ui/txt_" + archivos[i] + ".png");
      maxAncho = max(maxAncho, etiquetas[i].width);
    }
    escalaBase = min(1, 0.72 * anchoNormal / maxAncho);   // Escala común de las etiquetas
    reiniciar();
  }

  // Reinicio (selecciona la primera opción)
  void reiniciar() {
    seleccion = 0;
    for (int i = 0; i < n; i++) t[i] = (i == seleccion) ? 1 : 0;
    tiempoAviso = 0;
    calcularLayout();
  }

  // Posiciones: los botones se apilan y el seleccionado es más grande
  void calcularLayout() {
    float y = yInicio;
    for (int i = 0; i < n; i++) {
      bw[i] = lerp(anchoNormal, anchoGrande, t[i]);
      bh[i] = lerp(altoNormal, altoGrande, t[i]);
      bx[i] = 800 - bw[i] / 2;
      by[i] = y;
      y += bh[i] + separacion;
    }
    altoTotal = y - separacion - yInicio;
  }

  // Actualización (mouse + animación)
  void actualizar(float dt) {
    if (mouseX != pmouseX || mouseY != pmouseY) {
      int h = indiceBajoMouse();
      if (h >= 0) seleccion = h;
    }
    for (int i = 0; i < n; i++) {
      float objetivo = (i == seleccion) ? 1 : 0;
      t[i] += (objetivo - t[i]) * min(1, dt * 14);
    }
    if (tiempoAviso > 0) tiempoAviso -= dt;
    calcularLayout();
  }

  // Navegación con el teclado (devuelve la opción elegida o -1)
  int procesarTecla() {
    if (key == CODED) {
      if (keyCode == UP) mover(-1);
      else if (keyCode == DOWN) mover(1);
      return -1;
    }
    char k = Character.toLowerCase(key);
    if (k == 'w') mover(-1);
    else if (k == 's') mover(1);
    else if (key == ENTER || key == RETURN || key == ' ') return seleccion;
    return -1;
  }

  void mover(int d) {
    seleccion = (seleccion + d + n) % n;
  }

  // Parte del mouse
  int indiceBajoMouse() {
    for (int i = 0; i < n; i++) {
      if (mouseX >= ux(bx[i]) && mouseX <= ux(bx[i] + bw[i]) &&
          mouseY >= uy(by[i]) && mouseY <= uy(by[i] + bh[i])) return i;
    }
    return -1;
  }

  int clicEnMouse() {
    int h = indiceBajoMouse();
    if (h >= 0) seleccion = h;
    return h;
  }

  void mostrarAviso(String texto) {
    aviso = texto;
    tiempoAviso = 1.6;
  }

  // Dibujo (a = transparencia general 0 a 255)
  void dibujar(float a) {
    for (int i = 0; i < n; i++) {
      // Marco (fundido entre normal y grande)
      if (t[i] < 0.999) dibujarMarco(marcoNormal, i, a * (1 - t[i]));
      if (t[i] > 0.001) dibujarMarco(marcoGrande, i, a * t[i]);

      // Parte de la etiqueta
      float esc = min(escalaBase * lerp(1, 1.3, t[i]), 0.82 * anchoGrande / etiquetas[i].width);
      float lw = etiquetas[i].width * esc * uiS;
      float lh = etiquetas[i].height * esc * uiS;
      tint(255, a);
      image(etiquetas[i], ux(800) - lw / 2, uy(by[i] + bh[i] / 2) - lh / 2, lw, lh);

      // Flechas del botón seleccionado
      if (t[i] > 0.05) {
        float rebote = sin(millis() * 0.008) * 7;
        float fw = flechaIzq.width * uiS;
        float fh = flechaIzq.height * uiS;
        float fy = uy(by[i] + bh[i] / 2) - fh / 2;
        tint(255, a * t[i]);
        image(flechaIzq, ux(bx[i] - flechaIzq.width - 8 + rebote), fy, fw, fh);
        image(flechaDer, ux(bx[i] + bw[i] + 8 - rebote), fy, fw, fh);
      }
    }
    noTint();

    // Aviso (por ejemplo "próximamente")
    if (tiempoAviso > 0) {
      textAlign(CENTER, CENTER);
      textSize(26 * uiS);
      fill(0, 240, 255, min(255, tiempoAviso * 500) * (a / 255.0));
      text(aviso, ux(800), uy(min(yInicio + altoTotal + 30, 850)));
    }
  }

  // Marco en 3 piezas (izquierda, centro estirado, derecha)
  void dibujarMarco(PImage[] m, int i, float a) {
    float izqW = m[0].width;
    float derW = m[2].width;
    tint(255, a);
    image(m[0], ux(bx[i]), uy(by[i]), izqW * uiS + 1, bh[i] * uiS);
    image(m[1], ux(bx[i] + izqW), uy(by[i]), (bw[i] - izqW - derW) * uiS + 1, bh[i] * uiS);
    image(m[2], ux(bx[i] + bw[i] - derW), uy(by[i]), derW * uiS, bh[i] * uiS);
  }
}


// =====================================================
//  Pantalla de carga -> logo sube -> menú principal
// =====================================================
final int FASE_CARGA = 0, FASE_LOGO = 1, FASE_MENU = 2;
int fase = FASE_CARGA;

// Carga (simulada)
float progreso = 0, objetivoCarga = 0;
float tiempoPaso = 0.2;
float espera = 0.5;

// Movimiento del logo (de la pantalla de carga a la de inicio)
final float Y_CARGA = 390;   // Centro del logo durante la carga
final float Y_MENU  = 187;   // Centro del logo en el menú
float logoY = Y_CARGA;
float tMov = 0;
float aparicion = 0;         // Fundido de entrada del menú

// Actualización por fase
void actualizarInicio(float dt) {
  if (fase == FASE_CARGA) {
    // Avance a saltos para que parezca una carga real
    tiempoPaso -= dt;
    if (tiempoPaso <= 0) {
      objetivoCarga = min(1, objetivoCarga + random(0.05, 0.18));
      tiempoPaso = random(0.12, 0.4);
    }
    progreso += (objetivoCarga - progreso) * min(1, dt * 7);
    if (objetivoCarga >= 1 && progreso > 0.995) {
      progreso = 1;
      espera -= dt;
      if (espera <= 0) fase = FASE_LOGO;
    }
  } else if (fase == FASE_LOGO) {
    // Logo subiendo a su lugar del menú
    tMov = min(1, tMov + dt / 1.1);
    logoY = lerp(Y_CARGA, Y_MENU, suavizar(tMov));
    if (tMov >= 1) fase = FASE_MENU;
  } else {
    aparicion = min(1, aparicion + dt / 0.5);
    menuInicio.actualizar(dt);
  }
}

// Dibujo por fase
void dibujarInicio() {
  background(FONDO_MENU);

  // Logo con un pequeño parpadeo neón
  tint(255, 245 + 10 * sin(millis() * 0.004));
  image(logoImg, ux(800) - logoImg.width * uiS / 2, uy(logoY) - logoImg.height * uiS / 2,
        logoImg.width * uiS, logoImg.height * uiS);
  noTint();

  // Barra de carga
  if (fase == FASE_CARGA) dibujarBarraCarga(255);
  else if (fase == FASE_LOGO) dibujarBarraCarga(255 * (1 - min(1, tMov * 3)));

  // Parte del menú
  if (fase == FASE_MENU) menuInicio.dibujar(255 * aparicion);
}

// Barra de carga neón con segmentos
void dibujarBarraCarga(float a) {
  if (a <= 0) return;
  float bw = 760, bh = 34, by = 590;
  float x = ux(800 - bw / 2), y = uy(by), w = bw * uiS, h = bh * uiS;

  // Brillo exterior
  noFill();
  for (int i = 3; i >= 1; i--) {
    stroke(0, 240, 255, a * 0.07 * (4 - i));
    strokeWeight(i * 6 * uiS);
    rect(x, y, w, h, 6 * uiS);
  }

  // Marco
  stroke(0, 240, 255, a);
  strokeWeight(3 * uiS);
  rect(x, y, w, h, 6 * uiS);

  // Relleno por segmentos (Barra de carga)
  int segs = 38;
  float margen = 7 * uiS;
  float segW = (w - margen * 2) / segs;
  int llenos = floor(progreso * segs);
  noStroke();
  for (int i = 0; i < llenos; i++) {
    fill(lerpColor(CIAN, MAGENTA, i / (float) (segs - 1)), a);
    rect(x + margen + i * segW + 1.5 * uiS, y + margen, segW - 3 * uiS, h - margen * 2);
  }
  strokeWeight(1);

  // Parte del texto de porcentaje
  fill(0, 240, 255, a);
  textAlign(CENTER, CENTER);
  textSize(26 * uiS);
  text("CARGANDO...  " + int(progreso * 100) + "%", ux(800), y + h + 38 * uiS);
}

// Acciones del menú principal
void accionInicio(int opcion) {
  if (opcion < 0 || fundiendo) return;
  if (opcion == 0) irA(ESTADO_HABITACION);                                      // Iniciar Juego
  else if (opcion == 1) menuInicio.mostrarAviso("Configuración: próximamente");  // Configuración
  else if (opcion == 2) exit();                                                  // Salir
}


// =====================================================
//  Difumina la pantalla y muestra el menú neón (tecla M)
// =====================================================
boolean pausaActiva = false;
boolean pausaSolicitada = false;   // Se captura al final del frame
PGraphics fondoPausa;
float aparicionPausa = 0;

// Captura y difuminado de lo que hay en pantalla
void capturarPausa() {
  PImage captura = get();
  captura.resize(max(1, width / 12), 0);
  captura.filter(BLUR, 1);
  captura.resize(max(1, width / 3), 0);
  captura.filter(BLUR, 3);

  fondoPausa = createGraphics(width, height);
  fondoPausa.beginDraw();
  fondoPausa.image(captura, 0, 0, width, height);
  fondoPausa.noStroke();
  fondoPausa.fill(0, 5, 19, 140);
  fondoPausa.rect(0, 0, width, height);
  fondoPausa.endDraw();

  pausaSolicitada = false;
  pausaActiva = true;
  aparicionPausa = 0;
  menuPausa.reiniciar();
}

void cerrarPausa() {
  pausaActiva = false;
  pausaSolicitada = false;
  fondoPausa = null;
}

void dibujarPausa(float dt) {
  aparicionPausa = min(1, aparicionPausa + dt / 0.2);
  menuPausa.actualizar(dt);
  image(fondoPausa, 0, 0);
  menuPausa.dibujar(255 * aparicionPausa);
}

// Acciones del menú de pausa
void accionPausa(int opcion) {
  if (opcion < 0) return;
  if (opcion == 0) cerrarPausa();                                                // Volver al juego
  else if (opcion == 1) menuPausa.mostrarAviso("Configuración: próximamente");   // Configuración
  else if (opcion == 2) exit();                                                  // Salir
}


// =====================================================
//  Fin del juego (3 errores)
// =====================================================
void dibujarFin(float dt) {
  background(FONDO_MENU);
  menuFin.actualizar(dt);

  // Título neón
  float esc = 0.78;
  image(imgFin, ux(800) - imgFin.width * esc * uiS / 2, uy(175) - imgFin.height * esc * uiS / 2,
        imgFin.width * esc * uiS, imgFin.height * esc * uiS);

  // Puntaje final
  fuente(false, 30 * uiS);
  fill(0, 240, 255);
  textAlign(CENTER, CENTER);
  text("Puntaje final: " + puntos, ux(800), uy(285));

  menuFin.dibujar(255);
}

// Acciones del menú de fin
void accionFin(int opcion) {
  if (opcion < 0 || fundiendo) return;
  if (opcion == 0) {                      // Seguir jugando (desde el cuarto)
    reiniciarAlCambiar = true;
    irA(ESTADO_HABITACION);
  } else if (opcion == 1) {               // Salir
    exit();
  }
}
