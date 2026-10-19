// =====================================================
//  Principal cff
// =====================================================

// ---------- Estados del juego ----------
final int ESTADO_HABITACION = 0;
final int ESTADO_PC         = 1;
final int ESTADO_INICIO     = 2;
final int ESTADO_INSTAGRAM  = 3;
final int ESTADO_FIN        = 4;
int estado = ESTADO_INICIO;

// ---------- Direcciones del personaje ----------
final int ABAJO = 0, IZQUIERDA = 1, DERECHA = 2, ARRIBA = 3;

// ---------- Objetos principales ----------
Habitacion habitacion;
Jugador jugador;
PantallaInstagram instagram;
MenuNeon menuInicio, menuPausa, menuFin;

// ---------- Bienestar y puntos (3 errores = fin del juego) ----------
final int VIDAS = 3;
int bienestar = VIDAS;
int puntos = 0;
int tiempoFin = 0;                         // Momento en que aparece "Fin del juego"
int ultimoPunto = -10000, ultimoError = -10000;

// ---------- Transición (fundido a negro) ----------
float fade = 0;
boolean fundiendo = false, oscureciendo = true;
boolean reiniciarAlCambiar = false;
int destinoFade;

// ---------- Teclas de movimiento ----------
boolean teclaArriba, teclaAbajo, teclaIzquierda, teclaDerecha;

// ---------- Tiempo ----------
int tiempoAnterior;
// (segundosJuego, el reloj del juego, está en Interfaz.pde)


void setup() {
  fullScreen();                                   
  cargarFuentes();                                // Fuentes con tildes (Gracias claude)
  textFont(fuenteNormal);

  // Recursos de menús
  calcularUI();
  cargarRecursosUI();

  // Carga de objetos
  habitacion = new Habitacion(loadImage("habitacion.png"), loadImage("pc.png"));
  jugador    = new Jugador(540, 650, loadImage("personaje.png"),
                           loadImage("personaje_cansado.png"), loadImage("personaje_agotado.png"));
  instagram  = new PantallaInstagram();
  menuInicio = new MenuNeon(new String[] {"iniciar", "config", "salir"}, 330, 760, 880);
  menuPausa  = new MenuNeon(new String[] {"volver", "config", "salir"}, 195, 820, 960);
  menuFin    = new MenuNeon(new String[] {"seguir", "salir"}, 360, 760, 880);

  tiempoAnterior = millis();
}

void draw() {
  // Tiempo entre frames (dt en segundos)
  float dt = (millis() - tiempoAnterior) / 1000.0;
  tiempoAnterior = millis();
  dt = min(dt, 0.05);

  background(0);
  cursor(ARROW);
  textFont(fuenteNormal, 32);

  // Menú de pausa 
  if (pausaActiva) {
    dibujarPausa(dt);
    return;
  }

  actualizarFade(dt);

  // El reloj del juego solo corre mientras se juega (no en el menú, el fin ni la pausa)
  if (estado == ESTADO_HABITACION || estado == ESTADO_PC || estado == ESTADO_INSTAGRAM) {
    segundosJuego += dt;
  }

  // Pantallas
  if (estado == ESTADO_INICIO) {
    actualizarInicio(dt);
    dibujarInicio();
  } else if (estado == ESTADO_HABITACION) {
    if (!fundiendo) {
      jugador.actualizar(dt, habitacion, teclaArriba, teclaAbajo, teclaIzquierda, teclaDerecha);
    } else {
      jugador.detener();
    }
    habitacion.dibujar(jugador);
    dibujarAyudaControles();
    dibujarHUD();
  } else if (estado == ESTADO_PC) {
    habitacion.dibujarPC();
    dibujarHUD();
  } else if (estado == ESTADO_INSTAGRAM) {
    instagram.dibujar();
    dibujarHUD();
  } else if (estado == ESTADO_FIN) {
    dibujarFin(dt);
  }

  // Fin del juego (tercer error)
  if (bienestar <= 0 && estado != ESTADO_FIN && estado != ESTADO_INICIO
      && !fundiendo && millis() >= tiempoFin) {
    irA(ESTADO_FIN);
  }

  dibujarFade();

  // Captura para la pausa (al final, con todo ya dibujado)
  if (pausaSolicitada) capturarPausa();
}


// =====================================================
//  Transición
// =====================================================
void irA(int destino) {
  if (fundiendo) return;
  destinoFade = destino;
  fundiendo = true;
  oscureciendo = true;
}

void actualizarFade(float dt) {
  if (!fundiendo) return;
  if (oscureciendo) {
    fade += 900 * dt;
    if (fade >= 255) {
      fade = 255;
      if (reiniciarAlCambiar) {          // Empezar de nuevo desde el cuarto
        reiniciarJuego();
        reiniciarAlCambiar = false;
      }
      estado = destinoFade;              // Cambio de pantalla en lo más oscuro
      if (estado == ESTADO_INSTAGRAM) instagram.alAbrir();   // Se actualizan los "hace X"
      oscureciendo = false;
    }
  } else {
    fade -= 900 * dt;
    if (fade <= 0) {
      fade = 0;
      fundiendo = false;
    }
  }
}

void dibujarFade() {
  if (fade <= 0) return;
  noStroke();
  fill(0, fade);
  rect(0, 0, width, height);
}

// Vuelve todo al comienzo (tras el "Fin del juego")
void reiniciarJuego() {
  bienestar = VIDAS;
  barraAnim = VIDAS;
  segundosJuego = 0;                     // El reloj empieza de nuevo
  puntos = 0;
  jugador.reiniciar();
  instagram.reiniciar();
  menuFin.reiniciar();
  soltarTeclas();
}


// =====================================================
//  Atajos del teclado
// =====================================================
void keyPressed() {
  // Pausa abierta: solo navega el menú
  if (pausaActiva) {
    if (key == ESC) {
      key = 0;
      cerrarPausa();
    } else if (key != CODED && Character.toLowerCase(key) == 'p') {
      cerrarPausa();
    } else {
      accionPausa(menuPausa.procesarTecla());
    }
    return;
  }

  // Menú principal
  if (estado == ESTADO_INICIO) {
    if (fase == FASE_MENU) accionInicio(menuInicio.procesarTecla());
    return;
  }

  // Fin del juego
  if (estado == ESTADO_FIN) {
    if (key == ESC) key = 0;
    accionFin(menuFin.procesarTecla());
    return;
  }

  // Salida del PC e Instagram (pa que no quite el juego ps)
  if (key == ESC && (estado == ESTADO_PC || estado == ESTADO_INSTAGRAM)) {
    key = 0;
    if (!fundiendo) irA(estado == ESTADO_PC ? ESTADO_HABITACION : ESTADO_PC);
    return;
  }

  // Menú de pausa (tecla P)
  if (key != CODED && Character.toLowerCase(key) == 'p') {
    if (!fundiendo && bienestar > 0) {
      soltarTeclas();
      pausaSolicitada = true;
    }
    return;
  }

  // Respuestas en Instagram (1/B, 2/I, 3/C)
  if (estado == ESTADO_INSTAGRAM) {
    if (key != CODED) instagram.tecla(Character.toLowerCase(key));
    return;
  }

  //   Controles de movimiento
  if (key == CODED) {
    if (keyCode == UP)    teclaArriba = true;
    if (keyCode == DOWN)  teclaAbajo = true;
    if (keyCode == LEFT)  teclaIzquierda = true;
    if (keyCode == RIGHT) teclaDerecha = true;
    return;
  }

  char k = Character.toLowerCase(key);
  if (k == 'w') teclaArriba = true;
  if (k == 's') teclaAbajo = true;
  if (k == 'a') teclaIzquierda = true;
  if (k == 'd') teclaDerecha = true;
  if (k == 'h') habitacion.depurar = !habitacion.depurar;   // Ver colisiones
  interactuar(k);
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == UP)    teclaArriba = false;
    if (keyCode == DOWN)  teclaAbajo = false;
    if (keyCode == LEFT)  teclaIzquierda = false;
    if (keyCode == RIGHT) teclaDerecha = false;
    return;
  }
  char k = Character.toLowerCase(key);
  if (k == 'w') teclaArriba = false;
  if (k == 's') teclaAbajo = false;
  if (k == 'a') teclaIzquierda = false;
  if (k == 'd') teclaDerecha = false;
}


// =====================================================
//  MOUSE
// =====================================================
void mousePressed() {
  if (pausaActiva) {
    accionPausa(menuPausa.clicEnMouse());
  } else if (estado == ESTADO_INICIO) {
    if (fase == FASE_MENU) accionInicio(menuInicio.clicEnMouse());
  } else if (estado == ESTADO_FIN) {
    accionFin(menuFin.clicEnMouse());
  } else if (estado == ESTADO_PC) {
    habitacion.clicPC();
  } else if (estado == ESTADO_INSTAGRAM) {
    instagram.clic();
  }
}

void mouseWheel(MouseEvent event) {
  if (estado == ESTADO_INSTAGRAM && !pausaActiva) {
    instagram.rueda(event.getCount());
  }
}


// =====================================================
//  INTERACCIÓN
// =====================================================

// Interacción con el PC (tecla E)
void interactuar(char k) {
  if (estado != ESTADO_HABITACION || fundiendo) return;
  if (k == 'e' && habitacion.enZonaPC(jugador)) {
    soltarTeclas();
    irA(ESTADO_PC);
  }
}

void soltarTeclas() {
  teclaArriba = false;
  teclaAbajo = false;
  teclaIzquierda = false;
  teclaDerecha = false;
}
