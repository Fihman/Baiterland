// =================================================================================
// Mensajes directos (DMs) Lista de conversaciones a la izquierda, chat a la derecha
// =================================================================================

final String USUARIO = "tu_usuario";

// ---------- Tipos de mensaje en la conversación ----------
final int MSG_FECHA = 0, MSG_RECIBIDO = 1, MSG_ENVIADO = 2;

// ---------- Tonos (el número coincide con la respuesta correcta) ----------
// 0 = Bloquear (1 o B)   1 = Algo mundano (2 o I)   2 = Aceptar y responder bien (3 o C)
final int TONO_NEGATIVO = 0, TONO_NEUTRO = 1, TONO_POSITIVO = 2, SIN_TONO = -1;

PImage avatarDefecto;           // Foto por defecto de los usuarios bloqueados


// ---------- Un mensaje ----------
class MensajeDM {
  int tipo;
  String texto;
  int tono = SIN_TONO;          // Solo los mensajes que hay que responder
  String[] respuestas;          // Respuestas prefabricadas (la 0 no se usa: bloquear no responde)
  boolean bloqueado = false;
  boolean saludo = false;       // Un saludo se responde con otro saludo (solo bloquearlo es error)
  boolean revelado = false;     // Mensaje bloqueado que el jugador decidió ver (clic en la burbuja)
  float zx, zy, zw, zh;         // Dónde se dibujó la burbuja (para detectar el clic)

  MensajeDM(int tipo_, String texto_) {
    tipo = tipo_;
    texto = texto_;
  }

  // Mensaje recibido con tono y sus dos respuestas posibles
  MensajeDM(String texto_, int tono_, String respuestaNeutra, String respuestaPositiva) {
    tipo = MSG_RECIBIDO;
    texto = texto_;
    tono = tono_;
    respuestas = new String[] {"", respuestaNeutra, respuestaPositiva};
  }

  // Saludo del final de la conversación (no tiene tono: cualquier saludo de vuelta es correcto)
  MensajeDM(String texto_, String saludoNeutro, String saludoAmable) {
    tipo = MSG_RECIBIDO;
    texto = texto_;
    tono = TONO_NEUTRO;
    saludo = true;
    respuestas = new String[] {"", saludoNeutro, saludoAmable};
  }
}


// ---------- Una conversación (los mensajes se guardan en un arreglo) ----------
class Conversacion {
  String nombre;
  float minutosUltimo;      // Cuándo fue el último mensaje (minutos del juego; negativo = antes de empezar)
  PImage avatar;
  boolean noLeida = true;   // Punto azul
  boolean bloqueada = false;  // Al bloquear, pasa a ser "Usuario de Instagram" y no escribe más
  MensajeDM[] mensajes = new MensajeDM[80];
  int cantidad = 0;

  // Juego de esta conversación: los mensajes llegan por separado en cada chat
  MensajeDM[] eventos;            // Mensajes en el orden en que llegan
  int siguiente = 0;              // Próximo mensaje por llegar
  MensajeDM pendiente;            // Mensaje que espera respuesta (null si no hay)
  float llegadaEn = -1;           // Cuándo llega el siguiente (segundos del juego)
  boolean terminado = false;      // Ya no quedan mensajes

  Conversacion(String nombre_, PImage avatar_, float minutosAtras, MensajeDM[] iniciales) {
    nombre = nombre_;
    avatar = avatar_;
    minutosUltimo = -minutosAtras;
    for (int i = 0; i < iniciales.length; i++) agregar(iniciales[i]);
  }

  void agregar(MensajeDM m) {
    if (cantidad < mensajes.length) mensajes[cantidad++] = m;
  }

  // Nombre y foto que se ven (bloqueada = usuario anónimo con foto por defecto)
  String nombreVisible() { return bloqueada ? "Usuario de Instagram" : nombre; }
  PImage avatarVisible() { return bloqueada ? avatarDefecto : avatar; }

  // Vista previa (Último mensaje)
  String vistaPrevia() {
    for (int i = cantidad - 1; i >= 0; i--) {
      MensajeDM m = mensajes[i];
      if (m.tipo == MSG_FECHA) continue;
      if (m.bloqueado) return "Mensaje bloqueado";
      return (m.tipo == MSG_ENVIADO) ? "Tú: " + m.texto : m.texto;
    }
    return "";
  }
}


// ---------- La pantalla ----------
class PantallaInstagram {
  // ---------- Dimensiones del diseño (píxeles de referencia) ----------
  final float W = 1024, H = 746;
  final float LISTA_W = 385;     // Ancho del panel izquierdo
  final float CAB_H   = 72;      // Alto de las cabeceras
  final float PIE_Y   = 668;     // Inicio de la barra de mensaje
  final float ITEM_Y0 = 120;     // Inicio de la lista de conversaciones
  final float ITEM_H  = 78;      // Alto de cada conversación
  final float LINEA   = 20;      // Alto de línea de los mensajes
  final float ANCHO_TEXTO = 236; // Ancho máximo del texto en una burbuja

  // ---------- Botones de respuesta (abajo del chat) ----------
  final float CHIP_X0 = 405, CHIP_Y = 678, CHIP_W = 190, CHIP_H = 48, CHIP_GAP = 7.5;

  // ---------- Colores ----------
  final int AZUL         = 0xFF0095F6;
  final int NEGRO        = 0xFF262626;
  final int GRIS_TEXTO   = 0xFF8E8E8E;
  final int GRIS_LINEA   = 0xFFDBDBDB;
  final int GRIS_BURBUJA = 0xFFEFEFEF;
  final int FONDO        = 0xFF0A0E19;

  PImage[] avatares;
  Conversacion[] conversaciones;
  int seleccion = 0;              // Conversación abierta
  float scroll = 0;               // Desplazamiento hacia mensajes anteriores
  float maxScroll = 0;
  float s, ox, oy;                // Escala y posición de la ventana en pantalla
  float minutosVista = 0;         // Hora del juego (en minutos) en que se abrió Instagram

  PantallaInstagram() {
    avatarDefecto = loadImage("ig/avatar_default.png");
    avatares = new PImage[] {
      loadImage("ig/avatar_valeria.png"), loadImage("ig/avatar_camila.png"),
      loadImage("ig/avatar_mateo.png"), loadImage("ig/avatar_santiago.png")
    };

    // Ajuste de la pantalla 
    s  = min(width * 0.90 / W, height * 0.84 / H);
    ox = (width - W * s) / 2;
    oy = (height - H * s) / 2 + height * 0.02;

    reiniciar();
  }

  // ---------- Conversaciones (todas terminan con un saludo) ----------
  Conversacion[] crearConversaciones() {
    return new Conversacion[] {

      new Conversacion("Valeria", avatares[0], 6, new MensajeDM[] {
        new MensajeDM(MSG_FECHA, "Ayer 10:42 AM"),
        new MensajeDM(MSG_RECIBIDO, "Hola, ¿cómo estás?"),
        new MensajeDM(MSG_ENVIADO, "Todo bien, ¿y tú?"),
        new MensajeDM(MSG_FECHA, "Hoy 5:10 PM"),
        new MensajeDM(MSG_RECIBIDO, "676767676767"),
        new MensajeDM(MSG_RECIBIDO, "Para entender la historia de five nights at freddy..."),
        new MensajeDM(MSG_FECHA, "Hoy 5:18 PM"),
        new MensajeDM("Holaaa, ¿cómo andas?", "Hola, todo bien", "¡Hola Vale! Todo bien, ¿y tú cómo andas?")
      }),

      new Conversacion("Camila", avatares[1], 12, new MensajeDM[] {
        new MensajeDM(MSG_FECHA, "Ayer 8:15 PM"),
        new MensajeDM(MSG_ENVIADO, "Hola Cami"),
        new MensajeDM(MSG_RECIBIDO, "Hola"),
        new MensajeDM(MSG_FECHA, "Hoy 6:30 AM"),
        new MensajeDM(MSG_RECIBIDO, "Haz el proyecto putita"),
        new MensajeDM(MSG_FECHA, "Hoy 5:12 PM"),
        new MensajeDM("Buenas, ¿cómo vas?", "Buenas, bien", "¡Buenas Cami! Bien, ¿y tú qué tal?")
      }),

      new Conversacion("Mateo", avatares[2], 4, new MensajeDM[] {
        new MensajeDM(MSG_FECHA, "Ayer 3:05 PM"),
        new MensajeDM(MSG_RECIBIDO, "Exxx1"),
        new MensajeDM(MSG_ENVIADO, "Cff"),
        new MensajeDM(MSG_RECIBIDO, "Ujum"),
        new MensajeDM(MSG_FECHA, "Hoy 5:20 PM"),
        new MensajeDM("Quiubo, ¿cómo andas?", "Quiubo, bien", "¡Quiubo Mateo! Todo bien, ¿y tú?")
      }),

      new Conversacion("Santiago", avatares[3], 1176, new MensajeDM[] {
        new MensajeDM(MSG_FECHA, "Ayer 9:48 PM"),
        new MensajeDM("Ey", "Ey", "¡Ey Santi! ¿Cómo andas?")
      })
    };
  }

  // ---------- Mensajes de cada chat (texto, tono, respuesta mundana, respuesta positiva) ----------
  // El primero de cada chat es fijo; los demás salen en desorden
  MensajeDM[] crearEventos(int chat) {
    if (chat == 0) {            // Valeria: lo siguiente es positivo -> se responde el saludo
      return new MensajeDM[] {
        new MensajeDM("Oye, la exposición de hoy te quedó muy buena", TONO_POSITIVO,
                      "Ah ok, bueno", "¡Muchas gracias! Me alegra que te haya gustado"),
        new MensajeDM("¿A qué hora salimos mañana?", TONO_NEUTRO,
                      "A las 6", "A las 6, ¡nos vemos!"),
        new MensajeDM("¿Mañana hay clase de Algoritmia?", TONO_NEUTRO,
                      "Sí, a las 7", "Sí, ¡nos vemos allá y mucho éxito!"),
        new MensajeDM("Gracias por apoyarme el otro día, eres un gran amigo", TONO_POSITIVO,
                      "De nada", "¡Para eso estamos! Me alegra poder ayudarte")
      };
    }
    if (chat == 1) {            // Camila: lo siguiente es negativo -> se ignora el saludo
      return new MensajeDM[] {
        new MensajeDM("Eres un fracasado, nadie te aguanta en el curso", TONO_NEGATIVO,
                      "Ok", "Gracias por tu opinión, que estés muy bien"),
        new MensajeDM("Si necesitas ayuda con la tarea, cuenta conmigo", TONO_POSITIVO,
                      "Vale", "¡Qué buena nota! Te lo agradezco mucho"),
        new MensajeDM("Mañana toca llevar el trabajo impreso", TONO_NEUTRO,
                      "Ok, gracias por avisar", "¡Gracias por el aviso, qué bueno que me escribiste!"),
        new MensajeDM("Todos dicen que eres un aburrido, mejor no vuelvas a escribir", TONO_NEGATIVO,
                      "Ya veo", "Respeto tu opinión, que estés bien")
      };
    }
    if (chat == 2) {            // Mateo: lo siguiente es neutro -> se responde el saludo
      return new MensajeDM[] {
        new MensajeDM("¿Viste el partido de anoche?", TONO_NEUTRO,
                      "Sí, estuvo reñido", "¡Sí, estuvo buenísimo! ¿Tú lo viste completo?"),
        new MensajeDM("Subí tu foto al grupo para que todos se rían de ti", TONO_NEGATIVO,
                      "Ya veo", "Gracias por avisarme, que tengas buen día"),
        new MensajeDM("La canción que me recomendaste está buenísima, ya la tengo en repetición", TONO_POSITIVO,
                      "Qué bueno", "¡Me alegra mucho que te gustara! Te paso más"),
        new MensajeDM("Si no me das tu contraseña le cuento a todos tu secreto", TONO_NEGATIVO,
                      "Después hablamos", "Tranquilo, hablemos con calma")
      };
    }
    return new MensajeDM[] {    // Santiago: lo siguiente es neutro -> se responde el "Ey"
      new MensajeDM("Tienes datos", TONO_NEUTRO,
                    "Sí, ¿qué necesitas?", "¡Claro, con gusto te ayudo!"),
      new MensajeDM("Te ganaste un premio, entra a este link y pon tu clave", TONO_NEGATIVO,
                    "Mmm, ok", "No gracias, no entro a links desconocidos"),
      new MensajeDM("Felicitaciones por tu nota en el parcial, te la merecías", TONO_POSITIVO,
                    "Gracias", "¡Gracias! Fue mucho esfuerzo, me alegra que lo notaras"),
      new MensajeDM("¿Qué tal estuvo la clase de hoy?", TONO_NEUTRO,
                    "Normal, vimos arreglos", "Estuvo buena, vimos arreglos. ¿Te cuento?")
    };
  }

  // Cada vez que se abre Instagram se actualizan los "Ahora", "15 min", "3 h"...
  void alAbrir() {
    minutosVista = segundosJuego * MIN_POR_SEGUNDO;
  }

  // Empieza todo de nuevo
  void reiniciar() {
    minutosVista = 0;
    conversaciones = crearConversaciones();
    seleccion = 0;
    scroll = 0;

    for (int i = 0; i < conversaciones.length; i++) {
      Conversacion c = conversaciones[i];
      c.eventos = crearEventos(i);
      for (int k = c.eventos.length - 1; k > 1; k--) {      // Desorden (el primero se queda)
        int j = 1 + int(random(k));
        MensajeDM tmp = c.eventos[k];
        c.eventos[k] = c.eventos[j];
        c.eventos[j] = tmp;
      }

      // Quien empieza con un mensaje positivo ya no escribe uno negativo
      if (c.eventos[0].tono == TONO_POSITIVO) c.eventos = sinNegativos(c.eventos);

      // Si lo siguiente es negativo, el saludo se deja sin responder y se evalúa el último mensaje sin leer
      if (c.eventos[0].tono == TONO_NEGATIVO) entregarSiguiente(i);
      else c.pendiente = c.mensajes[c.cantidad - 1];         // Si no, hay que responder el saludo
    }
    conversaciones[seleccion].noLeida = false;
  }

  MensajeDM[] sinNegativos(MensajeDM[] ev) {
    MensajeDM[] r = new MensajeDM[0];
    for (int k = 0; k < ev.length; k++) {
      if (ev[k].tono != TONO_NEGATIVO) r = (MensajeDM[]) append(r, ev[k]);
    }
    return r;
  }

  // Llega el siguiente mensaje a la conversación i
  void entregarSiguiente(int i) {
    Conversacion c = conversaciones[i];
    if (c.siguiente >= c.eventos.length) {
      c.terminado = true;
      c.pendiente = null;
      c.agregar(new MensajeDM(MSG_FECHA, "Sin mensajes nuevos"));
      return;
    }
    // La hora del mensaje sale del reloj del juego (el mismo del PC)
    float cuando = (c.llegadaEn > 0) ? c.llegadaEn : segundosJuego;
    c.agregar(new MensajeDM(MSG_FECHA, etiquetaTiempo(cuando)));
    c.pendiente = c.eventos[c.siguiente++];
    c.llegadaEn = -1;
    c.agregar(c.pendiente);
    c.minutosUltimo = cuando * MIN_POR_SEGUNDO;
    c.noLeida = (seleccion != i);
    if (seleccion == i) scroll = 0;
  }

  // ---------- Respuestas del jugador (0 = 1/B, 1 = 2/I, 2 = 3/C) ----------
  boolean opcionesActivas() {
    return conversaciones[seleccion].pendiente != null && bienestar > 0;
  }

  void responder(int opcion) {
    if (!opcionesActivas()) return;
    Conversacion c = conversaciones[seleccion];
    MensajeDM m = c.pendiente;

    if (opcion == 0) {                                                     // Bloquear
      m.bloqueado = true;
      c.bloqueada = true;
      c.terminado = true;                    // Un usuario bloqueado ya no escribe más
    } else {
      c.agregar(new MensajeDM(MSG_ENVIADO, m.respuestas[opcion]));         // Respuesta prefabricada
    }

    // Un saludo acepta cualquier respuesta menos bloquear
    boolean acierto = m.saludo ? (opcion != 0) : (opcion == m.tono);
    if (acierto) {
      puntos += 100;
      ultimoPunto = millis();
    } else {                                 // Error: baja el bienestar
      bienestar--;
      ultimoError = millis();
      if (bienestar <= 0) tiempoFin = millis() + 1400;
    }

    c.pendiente = null;
    if (!c.bloqueada) c.llegadaEn = segundosJuego + random(1, 29);   // Entre 1 y 29 s (1 s = 2 min del juego)
    scroll = 0;
  }

  // Teclas: 1 o B, 2 o I, 3 o C
  void tecla(char k) {
    if (k == '1' || k == 'b') responder(0);
    else if (k == '2' || k == 'i') responder(1);
    else if (k == '3' || k == 'c') responder(2);
  }

  // Mouse en coordenadas del diseño
  float mx() { return (mouseX - ox) / s; }
  float my() { return (mouseY - oy) / s; }

  // Conversación bajo el mouse (-1 si ninguna)
  int indiceLista() {
    float x = mx(), y = my();
    if (x < 0 || x > LISTA_W) return -1;
    for (int i = 0; i < conversaciones.length; i++) {
      float yi = ITEM_Y0 + i * ITEM_H;
      if (y >= yi && y < yi + ITEM_H) return i;
    }
    return -1;
  }

  // Botón de respuesta bajo el mouse (-1 si ninguno)
  int chipBajoMouse() {
    if (!opcionesActivas()) return -1;
    for (int i = 0; i < 3; i++) {
      float x = CHIP_X0 + i * (CHIP_W + CHIP_GAP);
      if (mx() >= x && mx() <= x + CHIP_W && my() >= CHIP_Y && my() <= CHIP_Y + CHIP_H) return i;
    }
    return -1;
  }

  // Mensaje bloqueado (todavía oculto) bajo el mouse en el chat abierto
  MensajeDM bloqueadoBajoMouse() {
    Conversacion c = conversaciones[seleccion];
    if (my() < CAB_H || my() > PIE_Y) return null;
    for (int i = 0; i < c.cantidad; i++) {
      MensajeDM m = c.mensajes[i];
      if (m.bloqueado && !m.revelado && mx() >= m.zx && mx() <= m.zx + m.zw
          && my() >= m.zy && my() <= m.zy + m.zh) return m;
    }
    return null;
  }

  // Interacción
  void clic() {
    int c = chipBajoMouse();
    if (c >= 0) {
      responder(c);
      return;
    }
    MensajeDM b = bloqueadoBajoMouse();      // "Toca para ver"
    if (b != null) {
      b.revelado = true;
      return;
    }
    int i = indiceLista();
    if (i >= 0) abrir(i);
  }

  void abrir(int i) {
    seleccion = i;
    conversaciones[i].noLeida = false;   // Al abrirla queda leída
    scroll = 0;
  }

  void rueda(float cantidad) {
    scroll = constrain(scroll - cantidad * 40, 0, maxScroll);
  }


  void dibujar() {
    // Llegan los siguientes mensajes de cada chat cuando se cumple el tiempo
    for (int i = 0; i < conversaciones.length; i++) {
      Conversacion c = conversaciones[i];
      if (c.pendiente == null && !c.terminado && c.llegadaEn > 0 && bienestar > 0 && segundosJuego >= c.llegadaEn) {
        entregarSiguiente(i);
      }
    }

    background(FONDO);

    if ((indiceLista() >= 0 || chipBajoMouse() >= 0 || bloqueadoBajoMouse() != null) && !fundiendo) cursor(HAND);

    pushMatrix();
    translate(ox, oy);
    scale(s);

    // Panel blanco
    noStroke();
    fill(255);
    rect(0, 0, W, H);

    dibujarChat(conversaciones[seleccion]);
    dibujarLista();

    // Lo que se sale de la ventana al hacer scroll
    noStroke();
    fill(FONDO);
    rect(-40, H, W + 80, 400);
    rect(-40, -400, W + 80, 400);

    // Líneas divisorias
    stroke(GRIS_LINEA);
    strokeWeight(1);
    line(0, CAB_H, W, CAB_H);
    line(LISTA_W, 0, LISTA_W, H);
    popMatrix();

    // Pista para salir
    if (!fundiendo) {
      dibujarBurbujaTecla("ESC", "Volver al computador", width / 2, height * 0.065, false);
    }
  }

  // ---------- Dms ----------
  void dibujarLista() {
    noStroke();
    fill(255);
    rect(0, 0, LISTA_W, H);

    // Usuario + redactar
    fuente(true, 19);
    fill(NEGRO);
    textAlign(CENTER, CENTER);
    float cx = LISTA_W / 2 - 10;
    text(USUARIO, cx, 38);
    chevron(cx + textWidth(USUARIO) / 2 + 16, 40);
    iconoRedactar(349, 38);

    // Pestañas
    fuente(true, 14.5);
    textAlign(LEFT, CENTER);
    fill(NEGRO);
    text("PRINCIPAL", 29, 95);
    fill(GRIS_TEXTO);
    text("GENERAL", 141, 95);
    fill(AZUL);
    textAlign(RIGHT, CENTER);
    text("Solicitudes (1)", 361, 95);
    stroke(GRIS_LINEA);
    strokeWeight(1);
    line(0, 119, LISTA_W, 119);
    stroke(NEGRO);
    strokeWeight(1.5);
    line(7, 119, 121, 119);

    // Parte de cada conversación
    int hover = indiceLista();
    for (int i = 0; i < conversaciones.length; i++) {
      Conversacion c = conversaciones[i];
      float y = ITEM_Y0 + i * ITEM_H;

      noStroke();
      if (i == seleccion) fill(GRIS_BURBUJA);
      else if (i == hover) fill(250);
      else fill(255);
      rect(0, y + 1, LISTA_W - 1, ITEM_H);

      image(c.avatarVisible(), 28, y + 11, 56, 56);

      fuente(true, 15);
      fill(NEGRO);
      textAlign(LEFT, CENTER);
      text(recortarTexto(c.nombreVisible(), 230), 102, y + 28);

      String sufijo = " · " + tiempoTranscurrido(minutosVista - c.minutosUltimo);
      fuente(c.noLeida, 14);
      fill(c.noLeida ? NEGRO : GRIS_TEXTO);
      float anchoSufijo = textWidth(sufijo);
      text(recortarTexto(c.vistaPrevia(), 236 - anchoSufijo) + sufijo, 102, y + 50);

      if (c.noLeida) {
        noStroke();
        fill(AZUL);
        ellipse(357, y + 39, 9, 9);
      }
    }
  }

  // ---------- Chat abierto ----------
  void dibujarChat(Conversacion c) {
    float x0 = LISTA_W;
    float panelW = W - x0;

    // Alto de cada mensaje
    fuente(false, 15);
    ArrayList<ArrayList<String>> lineas = new ArrayList<ArrayList<String>>();
    float[] alturas = new float[c.cantidad];
    float total = 0;
    for (int i = 0; i < c.cantidad; i++) {
      MensajeDM m = c.mensajes[i];
      if (m.tipo == MSG_FECHA) {
        lineas.add(null);
        alturas[i] = 46;
      } else {
        boolean oculto = m.bloqueado && !m.revelado;
        ArrayList<String> l;
        if (oculto) {                      // Burbuja de "contenido no disponible"
          l = new ArrayList<String>();
          l.add("Este contenido no está disponible");
          l.add("Un usuario bloqueado envió este mensaje.");
        } else {
          l = ajustarTexto(m.texto, ANCHO_TEXTO);
        }
        lineas.add(l);
        alturas[i] = l.size() * LINEA + 24 + 8 + (oculto ? 22 : 0);     // +22 por "Toca para ver"
      }
      total += alturas[i];
    }

    // El último mensaje queda abajo
    float fondoMensajes = PIE_Y - 10;
    maxScroll = max(0, total - (fondoMensajes - CAB_H));
    scroll = constrain(scroll, 0, maxScroll);
    float y = fondoMensajes - total + scroll;

    // Mensajes
    for (int i = 0; i < c.cantidad; i++) {
      MensajeDM m = c.mensajes[i];
      float h = alturas[i];
      if (y + h > CAB_H - 20 && y < PIE_Y) {
        if (m.tipo == MSG_FECHA) {
          fuente(false, 12.5);
          fill(GRIS_TEXTO);
          textAlign(CENTER, CENTER);
          text(m.texto, x0 + panelW / 2, y + 23);
        } else {
          dibujarBurbuja(c, i, lineas.get(i), y);
        }
      }
      y += h;
    }

    // Máscaras de cabecera y barra de mensaje
    noStroke();
    fill(255);
    rect(x0 + 1, 0, panelW, CAB_H);
    rect(x0 + 1, PIE_Y, panelW, H - PIE_Y);

    dibujarCabeceraChat(c);
    if (opcionesActivas()) dibujarOpciones();
    else dibujarBarraMensaje(c);
  }

  // Burbuja de mensaje
  void dibujarBurbuja(Conversacion c, int i, ArrayList<String> l, float y) {
    MensajeDM m = c.mensajes[i];
    boolean enviado = (m.tipo == MSG_ENVIADO);
    boolean oculto = m.bloqueado && !m.revelado;

    fuente(false, 15);
    float ancho = 0;
    for (int k = 0; k < l.size(); k++) ancho = max(ancho, textWidth(l.get(k)));
    float bw = ancho + 36;
    float bh = l.size() * LINEA + 24;
    float bx = enviado ? (W - 32 - bw) : (LISTA_W + 58);

    if (enviado || oculto) {
      noStroke();
      fill(GRIS_BURBUJA);
    } else {
      stroke(GRIS_LINEA);
      strokeWeight(1);
      fill(255);
    }
    rect(bx, y, bw, bh, min(22, bh / 2));

    noStroke();
    textAlign(LEFT, CENTER);
    for (int k = 0; k < l.size(); k++) {
      fill(oculto && k == 1 ? GRIS_TEXTO : NEGRO);      // La segunda línea del aviso va en gris
      text(l.get(k), bx + 18, y + 12 + k * LINEA + LINEA / 2);
    }

    // Zona de clic y pista para ver el mensaje bloqueado
    m.zx = bx;
    m.zy = y;
    m.zw = bw;
    m.zh = bh;
    if (oculto) {
      fuente(false, 12.5);
      fill(GRIS_TEXTO);
      textAlign(LEFT, TOP);
      text("Toca para ver", bx + 4, y + bh + 6);
    }

    // Avatar pequeño (en el último mensaje recibido de un grupo)
    boolean ultimoDelGrupo = (i == c.cantidad - 1) || (c.mensajes[i + 1].tipo != MSG_RECIBIDO);
    if (!enviado && ultimoDelGrupo) image(c.avatarVisible(), LISTA_W + 20, y + bh - 28, 28, 28);
  }

  void dibujarCabeceraChat(Conversacion c) {
    image(c.avatarVisible(), 420, 16, 40, 40);
    fuente(true, 16);
    fill(NEGRO);
    textAlign(LEFT, CENTER);
    if (c.bloqueada) {                     // Nombre y debajo el usuario, como en Instagram
      text(c.nombreVisible(), 472, 30);
      fuente(false, 13);
      fill(GRIS_TEXTO);
      text("Usuario de Instagram", 472, 50);
    } else {
      text(c.nombre, 472, 36);
    }
    iconoTelefono(883, 40);
    iconoVideo(927, 40);
    iconoInfo(970, 40);
  }

  // Barra normal de mensaje (no se puede escribir)
  void dibujarBarraMensaje(Conversacion c) {
    stroke(GRIS_LINEA);
    strokeWeight(1);
    fill(255);
    rect(405, 678, 585, 48, 24);
    iconoCarita(440, 702);
    fuente(false, 15);
    fill(GRIS_TEXTO);
    textAlign(LEFT, CENTER);
    boolean escribiendo = (c.pendiente == null && !c.terminado && bienestar > 0);
    text(escribiendo ? c.nombre + " está escribiendo..." : "Mensaje...", 472, 702);
    iconoImagen(960, 702);
  }

  // Botones de respuesta: 1/B, 2/I y 3/C (en lugar de la barra de mensaje)
  void dibujarOpciones() {
    String[] teclas = {"1 · B", "2 · I", "3 · C"};
    String[] textos = {"Bloquear", "Responder normal", "Responder amable"};
    int hover = chipBajoMouse();

    for (int i = 0; i < 3; i++) {
      float x = CHIP_X0 + i * (CHIP_W + CHIP_GAP);

      stroke(GRIS_LINEA);
      strokeWeight(1);
      fill(i == hover ? 242 : 255);
      rect(x, CHIP_Y, CHIP_W, CHIP_H, 24);

      noStroke();
      fill(GRIS_BURBUJA);
      rect(x + 8, CHIP_Y + 9, 46, 30, 15);
      fuente(true, 12.5);
      fill(NEGRO);
      textAlign(CENTER, CENTER);
      text(teclas[i], x + 31, CHIP_Y + 23);

      fuente(false, 13.5);
      textAlign(LEFT, CENTER);
      text(textos[i], x + 62, CHIP_Y + 24);
    }
  }

  // =====================================================
  //  ÍCONOS (dibujados con formas)
  // =====================================================
  void chevron(float x, float y) {
    stroke(NEGRO);
    strokeWeight(2);
    line(x - 5, y - 2, x, y + 3);
    line(x, y + 3, x + 5, y - 2);
  }

  void iconoRedactar(float x, float y) {
    noFill();
    stroke(NEGRO);
    strokeWeight(2);
    rect(x - 11, y - 10, 20, 20, 5);
    strokeWeight(2.6);
    line(x - 3, y + 3, x + 9, y - 9);
  }

  // Auricular dibujado en una caja de 24 x 24 (centrada en x, y)
  void iconoTelefono(float x, float y) {
    pushMatrix();
    translate(x, y);
    scale(1.1);
    translate(-12, -12);
    noFill();
    stroke(NEGRO);
    strokeWeight(2);
    strokeJoin(ROUND);
    beginShape();
    vertex(22, 16.92);
    vertex(22, 19.92);
    bezierVertex(22, 21.02, 21.02, 22, 19.82, 21.92);
    bezierVertex(16.4, 21.7, 13.5, 20.6, 11.19, 18.85);
    bezierVertex(8.8, 17.1, 6.9, 15.2, 5.19, 12.85);
    bezierVertex(3.5, 10.5, 2.4, 7.5, 2.12, 4.18);
    bezierVertex(2.0, 2.9, 2.9, 2, 4.11, 2);
    vertex(7.11, 2);
    bezierVertex(8.2, 2, 9.0, 2.8, 9.11, 3.72);
    bezierVertex(9.25, 4.7, 9.5, 5.6, 9.81, 6.53);
    bezierVertex(9.95, 7.3, 9.8, 8.0, 9.36, 8.64);
    vertex(8.09, 9.91);
    bezierVertex(9.6, 12.2, 11.8, 14.4, 14.09, 15.91);
    vertex(15.36, 14.64);
    bezierVertex(16.0, 14.1, 16.8, 14.0, 17.47, 14.19);
    bezierVertex(18.4, 14.5, 19.3, 14.7, 20.28, 14.89);
    bezierVertex(21.3, 15.0, 22, 15.8, 22, 16.92);
    endShape(CLOSE);
    strokeJoin(MITER);
    popMatrix();
  }

  void iconoVideo(float x, float y) {
    noFill();
    stroke(NEGRO);
    strokeWeight(2);
    rect(x - 13, y - 8, 18, 16, 4);
    line(x + 5, y - 2, x + 12, y - 6);
    line(x + 12, y - 6, x + 12, y + 6);
    line(x + 12, y + 6, x + 5, y + 2);
  }

  void iconoInfo(float x, float y) {
    noFill();
    stroke(NEGRO);
    strokeWeight(2);
    ellipse(x, y, 26, 26);
    line(x, y - 1, x, y + 6);
    strokeWeight(3);
    point(x, y - 5);
  }

  void iconoCarita(float x, float y) {
    noFill();
    stroke(NEGRO);
    strokeWeight(2);
    ellipse(x, y, 24, 24);
    strokeWeight(2.6);
    point(x - 4.5, y - 3);
    point(x + 4.5, y - 3);
    strokeWeight(2);
    arc(x, y + 1, 13, 10, 0.25, PI - 0.25);
  }

  void iconoImagen(float x, float y) {
    noFill();
    stroke(NEGRO);
    strokeWeight(2);
    rect(x - 12, y - 11, 24, 22, 4);
    line(x - 11, y + 7, x - 4, y);
    line(x - 4, y, x + 2, y + 6);
    line(x + 2, y + 6, x + 5, y + 3);
    line(x + 5, y + 3, x + 11, y + 8);
    strokeWeight(3);
    point(x - 4, y - 4);
  }
}
