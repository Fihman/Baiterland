// =====================================================
// Necesario para los menús 
// =====================================================

// ---------- Colores neón ----------
final int CIAN       = 0xFF00F0FF;
final int MAGENTA    = 0xFFF028FA;
final int FONDO_MENU = 0xFF000513;

// ---------- Recursos de los menús ----------
PImage logoImg, flechaIzq, flechaDer, imgFin;
PImage[] marcoNormal = new PImage[3];   // izquierda, centro, derecha
PImage[] marcoGrande = new PImage[3];

// ---------- Espacio de diseño de menús (1600 x 874) ----------
final float UI_ANCHO = 1600, UI_ALTO = 874;
float uiS, uiOX, uiOY;

// Imágenes de los menús
void cargarRecursosUI() {
  logoImg   = loadImage("ui/logo.png");
  imgFin    = loadImage("ui/txt_fin.png");
  flechaIzq = loadImage("ui/flecha_izq.png");
  flechaDer = loadImage("ui/flecha_der.png");
  String[] partes = {"izq", "med", "der"};
  for (int i = 0; i < 3; i++) {
    marcoNormal[i] = loadImage("ui/marco_normal_" + partes[i] + ".png");
    marcoGrande[i] = loadImage("ui/marco_grande_" + partes[i] + ".png");
  }
}

  // Escala del espacio de diseño a la pantalla
void calcularUI() {
  uiS  = min(width / UI_ANCHO, height / UI_ALTO);
  uiOX = (width - UI_ANCHO * uiS) / 2;
  uiOY = (height - UI_ALTO * uiS) / 2;
}

float ux(float x) { return uiOX + x * uiS; }
float uy(float y) { return uiOY + y * uiS; }

// Fluidez
float suavizar(float t) {
  return (t < 0.5) ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
}

// ---------- Fuentes ----------
PFont fuenteNormal, fuenteNegrita;

void cargarFuentes() {
  fuenteNormal  = createFont("SansSerif", 32, true);
  fuenteNegrita = createFont("SansSerif.bold", 32, true);
}

// Cambio de fuente (normal o negrita) y tamaño
void fuente(boolean negrita, float tam) {
  textFont(negrita ? fuenteNegrita : fuenteNormal, tam);
}

// Texto en varias líneas (usa la fuente actual)
ArrayList<String> ajustarTexto(String t, float maxAncho) {
  ArrayList<String> lineas = new ArrayList<String>();
  String[] palabras = split(t, ' ');
  String linea = "";
  for (int i = 0; i < palabras.length; i++) {
    String prueba = (linea.length() == 0) ? palabras[i] : linea + " " + palabras[i];
    if (linea.length() == 0 || textWidth(prueba) <= maxAncho) {
      linea = prueba;
    } else {
      lineas.add(linea);
      linea = palabras[i];
    }
  }
  lineas.add(linea);
  return lineas;
}

// Texto recortado con "..." 
String recortarTexto(String t, float maxAncho) {
  if (textWidth(t) <= maxAncho) return t;
  while (t.length() > 1 && textWidth(t + "...") > maxAncho) {
    t = t.substring(0, t.length() - 1);
  }
  return t + "...";
}

// Lo de arriba ([E] Usar el computador)
// cx = centro horizontal, yBase = borde inferior de la burbuja
void dibujarBurbujaTecla(String tecla, String texto, float cx, float yBase, boolean flecha) {
  float tam = height * 0.024;
  fuente(false, tam);

  float pad  = tam * 0.6;
  float kapH = tam * 1.7;
  float kapW = max(kapH, textWidth(tecla) + pad * 1.4);
  float tw   = textWidth(texto);
  float bh   = kapH + pad;
  float bw   = pad * 0.5 + kapW + pad * 0.8 + tw + pad * 0.9;
  float bx   = cx - bw / 2;
  float by   = yBase - bh - (flecha ? 10 : 0);

  // Fondo de la burbuja
  fill(15, 20, 35, 235);
  stroke(120, 200, 255);
  strokeWeight(2);
  rect(bx, by, bw, bh, 12);
  strokeWeight(1);

  // Flecha hacia el personaje
  if (flecha) {
    noStroke();
    triangle(cx - 9, by + bh - 1, cx + 9, by + bh - 1, cx, by + bh + 10);
  }

  // Tecla
  noStroke();
  fill(255, 214, 90);
  float kx = bx + pad * 0.5;
  float ky = by + pad * 0.5;
  rect(kx, ky, kapW, kapH, 7);
  fill(30);
  textAlign(CENTER, CENTER);
  text(tecla, kx + kapW / 2, ky + kapH / 2 - tam * 0.08);

  // Texto
  fill(255);
  textAlign(LEFT, CENTER);
  text(texto, kx + kapW + pad * 0.8, by + bh / 2 - tam * 0.08);
}

// Ayuda de controles (abajo)
void dibujarAyudaControles() {
  textSize(height * 0.018);
  textAlign(CENTER, BOTTOM);
  fill(255, 140);
  text("WASD / Flechas: mover     E: interactuar     P: pausa     H: ver colisiones", width / 2, height - 12);
}

// =====================================================
//  Reloj del juego: 1 segundo real = 2 minutos del juego
//  (empieza el 14/09/2026 a las 5:24 PM y se refresca cada 10 min; lo usan el PC y los mensajes)
// =====================================================
float segundosJuego = 0;
final int MIN_POR_SEGUNDO = 2;

// Fecha y hora del juego después de "seg" segundos de partida
java.util.Calendar calendarioJuego(float seg) {
  java.util.Calendar cal = java.util.Calendar.getInstance();
  cal.set(2026, 8, 14, 17, 24, 0);
  int minutos = (int) (seg * MIN_POR_SEGUNDO);
  minutos -= minutos % 10;                      // La hora salta de 10 en 10 minutos
  cal.add(java.util.Calendar.MINUTE, minutos);
  return cal;
}

String horaJuego(float seg) {
  java.util.Calendar cal = calendarioJuego(seg);
  int h = cal.get(java.util.Calendar.HOUR_OF_DAY);
  int h12 = (h % 12 == 0) ? 12 : h % 12;
  return h12 + ":" + nf(cal.get(java.util.Calendar.MINUTE), 2) + (h >= 12 ? " PM" : " AM");
}

String fechaJuego(float seg) {
  java.util.Calendar cal = calendarioJuego(seg);
  return nf(cal.get(java.util.Calendar.DAY_OF_MONTH), 2) + "/" + nf(cal.get(java.util.Calendar.MONTH) + 1, 2)
         + "/" + cal.get(java.util.Calendar.YEAR);
}

// Hace cuánto pasó algo ("Ahora", "15 min", "3 h", "1 d") a partir de los minutos del juego
String tiempoTranscurrido(float minutos) {
  int m = (int) max(0, minutos);
  if (m < 1) return "Ahora";
  if (m < 60) return m + " min";
  if (m < 1440) return (m / 60) + " h";
  return (m / 1440) + " d";
}

// Etiqueta de los mensajes: "Hoy 5:39 PM" (o con fecha si ya pasó de día)
String etiquetaTiempo(float seg) {
  if (fechaJuego(seg).equals(fechaJuego(0))) return "Hoy " + horaJuego(seg);
  return fechaJuego(seg) + " " + horaJuego(seg);
}

// Barra de bienestar: se vacía suavecito y deja una estela roja del daño
float barraAnim = VIDAS;

// Bienestar y puntos (arriba a la derecha, discreto)
void dibujarHUD() {
  float m   = height * 0.022;
  float bw  = width * 0.085;
  float bh  = height * 0.010;
  float pad = height * 0.012;
  float tam = height * 0.016;
  float panelW = bw + pad * 2;
  float panelH = pad * 1.6 + tam * 1.35 + bh + tam * 0.5 + tam * 1.3;
  float px = width - m - panelW;
  float py = m;

  // Fondo
  noStroke();
  fill(0, 110);
  rect(px, py, panelW, panelH, 10);

  fuente(false, tam);
  textAlign(LEFT, TOP);
  fill(255, 160);
  text("Bienestar", px + pad, py + pad * 0.8);

  float by = py + pad * 0.8 + tam * 1.35;
  fill(255, 45);
  rect(px + pad, by, bw, bh, bh / 2);

  // Color según lo que quede: verde (3), naranja (2), rojo (1)
  int c = color(90, 220, 140);
  if (bienestar == VIDAS - 1) c = color(255, 150, 40);
  else if (bienestar < VIDAS - 1) c = color(235, 50, 50);

  // Daño: la barra se enrojece unos instantes, tiembla y vuelve a su color
  float dano = constrain(1 - (millis() - ultimoError) / 600.0, 0, 1);
  c = lerpColor(c, color(255, 30, 30), dano);
  float temblor = (dano > 0.5) ? random(-2, 2) : 0;

  barraAnim += (bienestar - barraAnim) * 0.12;   // Se anima hacia el valor real
  float bx = px + pad + temblor;
  fill(255, 90, 90, 200);                        // Estela del daño
  rect(bx, by, bw * barraAnim / (float) VIDAS, bh, bh / 2);
  fill(c);
  rect(bx, by, bw * min(bienestar, barraAnim) / (float) VIDAS, bh, bh / 2);

  // Divisiones (una por cada error permitido)
  stroke(0, 150);
  strokeWeight(2);
  for (int i = 1; i < VIDAS; i++) {
    line(bx + bw * i / VIDAS, by, bx + bw * i / VIDAS, by + bh);
  }
  noStroke();
  strokeWeight(1);

  // Puntos (debajo de la barra)
  boolean sube = millis() - ultimoPunto < 600;
  float yPuntos = by + bh + tam * 0.5;
  fill(sube ? color(120, 255, 170) : color(255, 190));
  textAlign(LEFT, TOP);
  text("Puntos: " + puntos, px + pad, yPuntos);

  // "+100pts" que sube de abajo hacia arriba por el contador y se desvanece
  int t = millis() - ultimoPunto;
  if (t < 1000) {
    float p = t / 1000.0;
    float a = 255 * min(1, p * 6) * (1 - max(0, (p - 0.5) / 0.5));    // Aparece rápido, se va al final
    float yAnim = yPuntos + tam * 2.4 - p * tam * 4.2;                  // Desde debajo hasta arriba del contador
    fuente(true, tam * 1.3);
    textAlign(RIGHT, TOP);
    fill(0, a * 0.6);
    text("+100pts", px + panelW - pad + 1.5, yAnim + 1.5);              // Sombra para que se lea
    fill(120, 255, 170, a);
    text("+100pts", px + panelW - pad, yAnim);
  }
}
