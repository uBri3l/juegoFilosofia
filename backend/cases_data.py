"""
Casos de Ética Profesional y motor de respaldo local ultrarrápido en español.
"""

import random

CASOS_DISPONIBLES = [
    {
        "id": "caso_algoritmo_medico",
        "titulo": "Caso 1: El Algoritmo de Triaje Clínico",
        "subtitulo": "Ingeniería de Software y Bioética Profesional",
        "abogado_rival": "Fiscal V. Krugger",
        "descripcion": (
            "Una desarrolladora senior filtró a las autoridades sanitarias que el algoritmo "
            "de triaje de su hospital privado descartaba pacientes mayores de 65 años sin seguro VIP. "
            "La empresa la demanda por violar el acuerdo de confidencialidad (NDA)."
        ),
        "turnos_banco": [
            {
                "rival_falacia": {
                    "dialogo": "¡Señoría! La acusada lleva apenas dos años en la empresa y se viste de forma informal; alguien tan joven no puede entender de algoritmos médicos ni de ética corporativa.",
                    "es_falacia": True,
                    "tipo_argumento_rival": "FALACIA",
                    "nombre_falacia": "Ad Hominem",
                    "explicacion_logica": "Ataca la edad y vestimenta de la ingeniera en lugar de refutar la evidencia del sesgo del algoritmo.",
                },
                "rival_medio": {
                    "dialogo": "La ingeniera firmó libremente un contrato de confidencialidad (NDA). Cumplir la palabra empeñada y los contratos es un deber ético fundamental en cualquier profesión.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "MEDIO",
                    "nombre_falacia": None,
                    "explicacion_logica": "Es un argumento válido en principio contractual, pero omite que ningún contrato privado está por encima de la vida humana.",
                },
                "rival_infalible": {
                    "dialogo": "Incluso ante un riesgo ético, los códigos deontológicos exigen agotar primero los canales internos de reporte de seguridad antes de exponer datos clínicos sensibles externamente.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "INFALIBLE",
                    "nombre_falacia": None,
                    "explicacion_logica": "Argumento sólido de deontología profesional sobre el procedimiento gradual de denuncia responsable.",
                },
                "opciones": [
                    {
                        "texto": "El código de ética de ingeniería prioriza la vida y seguridad pública sobre cualquier cláusula de confidencialidad privada cuando los reportes internos fueron ignorados.",
                        "tipo": "INFALIBLE",
                        "nombre_falacia": None,
                        "explicacion": "Argumento infalible: aplica la jerarquía de deberes deontológicos (principio de no maleficencia y supremacía del bienestar público).",
                    },
                    {
                        "texto": "El hospital tiene mucho dinero y seguro puede pagar una indemnización sin demandar a una trabajadora honesta.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: apela a la capacidad económica del hospital pero no resuelve el conflicto jurídico ni ético del NDA.",
                    },
                    {
                        "texto": "La ingeniera solo intentó ayudar porque sentía empatía por los pacientes mayores del hospital.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: la buena intención subjetiva atenúa la culpa, pero debe sustentarse en el deber objetivo de evitar un daño grave.",
                    },
                    {
                        "texto": "Si castigamos a esta ingeniera hoy, mañana ningún médico ni ingeniero volverá a salvar una sola vida y colapsarán todos los hospitales del país.",
                        "tipo": "FALACIA",
                        "nombre_falacia": "Pendiente Resbaladiza",
                        "explicacion": "Falacia de Pendiente Resbaladiza: encadena consecuencias extremas e improbables sin demostrar el nexo causal necesario.",
                    },
                ],
            },
            {
                "rival_falacia": {
                    "dialogo": "O protegemos absolutamente todos los secretos empresariales sin excepción, o destruimos por completo la industria tecnológica nacional. ¡No hay punto medio!",
                    "es_falacia": True,
                    "tipo_argumento_rival": "FALACIA",
                    "nombre_falacia": "Falso Dilema",
                    "explicacion_logica": "Presenta solo dos extremos radicales ignorando que se puede proteger la propiedad intelectual mientras se audita la seguridad médica.",
                },
                "rival_medio": {
                    "dialogo": "El algoritmo fue aprobado por el director comercial del hospital, por lo que la responsabilidad ética recaía únicamente en la gerencia y no en la programadora.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "MEDIO",
                    "nombre_falacia": None,
                    "explicacion_logica": "Argumento parcial: aunque la gerencia es responsable, el profesional técnico no puede escudarse en la obediencia debida ante un daño directo.",
                },
                "rival_infalible": {
                    "dialogo": "La filtración incluyó registros sin anonimizar de tres pacientes reales, vulnerando el deber ético de privacidad médica que podía haberse evitado anonimizando la prueba.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "INFALIBLE",
                    "nombre_falacia": None,
                    "explicacion_logica": "Señala con precisión un principio de proporcionalidad y minimización de daño en la revelación de pruebas.",
                },
                "opciones": [
                    {
                        "texto": "La responsabilidad profesional no se anula por órdenes superiores: auditar y denunciar sesgos letales ante el regulador sanitario con datos minimizados cumple el principio de proporcionalidad.",
                        "tipo": "INFALIBLE",
                        "nombre_falacia": None,
                        "explicacion": "Argumento infalible: integra autonomía moral del profesional, rechazo a la obediencia ciega y proporcionalidad ética.",
                    },
                    {
                        "texto": "Otros hospitales también usan algoritmos parecidos y nadie los ha auditado todavía.",
                        "tipo": "FALACIA",
                        "nombre_falacia": "Tu Quoque (Apelación a la práctica común)",
                        "explicacion": "Falacia: que otros cometan la misma falta ética no convierte la práctica en moralmente aceptable.",
                    },
                    {
                        "texto": "El software tenía errores de programación que tarde o temprano iban a salir a la luz en la prensa.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: describe un hecho probable pero no fundamenta la legitimidad ética de la actuación profesional.",
                    },
                    {
                        "texto": "La ingeniera dejó constancia en un correo interno una semana antes de acudir al ministerio.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: aporta un hecho relevante pero requiere conectarlo con la urgencia del riesgo vital para justificar la acción.",
                    },
                ],
            },
            {
                "rival_falacia": {
                    "dialogo": "El código fuente del hospital es infalible porque fue escrito por una empresa líder del mercado; y como es de una empresa líder, jamás puede equivocarse.",
                    "es_falacia": True,
                    "tipo_argumento_rival": "FALACIA",
                    "nombre_falacia": "Razonamiento Circular (Petición de Principio)",
                    "explicacion_logica": "Asume en la premisa exactamente lo mismo que intenta demostrar sin aportar evidencia técnica de equidad clínica.",
                },
                "rival_medio": {
                    "dialogo": "El sistema estadístico solo buscaba reducir tiempos de espera globales en la sala de urgencias usando datos históricos.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "MEDIO",
                    "nombre_falacia": None,
                    "explicacion_logica": "Explica la finalidad utilitaria del diseño, pero ignora la discriminación injusta contra un grupo vulnerable.",
                },
                "rival_infalible": {
                    "dialogo": "La evaluación de impacto algorítmico exigía presentar un informe técnico ante el comité de bioética del hospital para suspender el módulo sin interrumpir todo el servicio.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "INFALIBLE",
                    "nombre_falacia": None,
                    "explicacion_logica": "Argumento riguroso basado en gobernanza técnica y continuidad asistencial segura.",
                },
                "opciones": [
                    {
                        "texto": "Los principios de justicia distributiva y equidad en bioética prohíben que un sistema automatizado discrimine el acceso vital por nivel socioeconómico en urgencias.",
                        "tipo": "INFALIBLE",
                        "nombre_falacia": None,
                        "explicacion": "Argumento infalible: fundamenta el principio bioético de justicia e igualdad de trato en urgencias médicas.",
                    },
                    {
                        "texto": "Como ningún paciente falleció ese mismo día específico, la ingeniera no tenía motivo real para preocuparse.",
                        "tipo": "FALACIA",
                        "nombre_falacia": "Falacia del Francotirador / Sesgo de resultado",
                        "explicacion": "Falacia: evalúa la moralidad de una acción riesgosa solo por la suerte puntual de un día, ignorando el peligro sistémico.",
                    },
                    {
                        "texto": "Los médicos de guardia tampoco estaban de acuerdo con usar ese programa informático.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: muestra respaldo gremial, pero no constituye por sí solo la demostración deontológica.",
                    },
                    {
                        "texto": "Actualizar el servidor habría costado menos que el juicio actual.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio pragmático, pero secundario frente a los derechos fundamentales de los pacientes.",
                    },
                ],
            },
        ],
    },
    {
        "id": "caso_vertido_quimico",
        "titulo": "Caso 2: El Informe Hidrogeológico Oculto",
        "subtitulo": "Secreto Profesional vs. Salud Pública Ambiental",
        "abogado_rival": "Fiscal M. Vance",
        "descripcion": (
            "Un perito químico contratado por una minera descubrió arsénico filtrándose al acuífero "
            "de un pueblo vecino. Al negarse a alterar su informe y alertar al municipio, el colegio "
            "empresarial pide su inhabilitación por deslealtad al cliente."
        ),
        "turnos_banco": [
            {
                "rival_falacia": {
                    "dialogo": "El prestigioso Premio Nobel de Literatura afirmó hace años que la minería impulsa la cultura; por lo tanto, el informe químico de este perito sobre el arsénico es falso.",
                    "es_falacia": True,
                    "tipo_argumento_rival": "FALACIA",
                    "nombre_falacia": "Apelación a la Autoridad Irrelevante (Ad Verecundiam)",
                    "explicacion_logica": "Cita a una autoridad ajena al campo científico para refutar un análisis químico toxicológico.",
                },
                "rival_medio": {
                    "dialogo": "El cliente pagó los honorarios del estudio privado, de modo que los resultados pertenecen exclusivamente a la empresa contratante.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "MEDIO",
                    "nombre_falacia": None,
                    "explicacion_logica": "Argumento patrimonial ordinario, pero refutable porque la propiedad de un estudio no autoriza ocultar un peligro inminente para terceros.",
                },
                "rival_infalible": {
                    "dialogo": "El perito debía certificar la contramuestra con un segundo laboratorio acreditado antes de declarar la emergencia pública, asegurando rigor metodológico.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "INFALIBLE",
                    "nombre_falacia": None,
                    "explicacion_logica": "Argumento sólido basado en el deber de diligencia científica y verificación técnica.",
                },
                "opciones": [
                    {
                        "texto": "La veracidad científica y la protección de terceros frente a un riesgo tóxico inminente son deberes inalienables que prevalecen sobre el interés comercial del cliente.",
                        "tipo": "INFALIBLE",
                        "nombre_falacia": None,
                        "explicacion": "Argumento infalible: aplica los principios de integridad científica, no maleficencia y límite ético del secreto profesional ante daño grave.",
                    },
                    {
                        "texto": "Todo el pueblo cree en redes sociales que la minera es culpable, así que el perito tenía toda la razón desde el principio.",
                        "tipo": "FALACIA",
                        "nombre_falacia": "Ad Populum (Apelación a la mayoría)",
                        "explicacion": "Falacia Ad Populum: la validez de un hallazgo químico depende de la evidencia empírica, no de la opinión popular.",
                    },
                    {
                        "texto": "El perito cobró menos de lo habitual por ese informe, lo que demuestra su desinterés económico.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: habla bien de su motivación, pero es secundario frente a la obligación deontológica de reportar riesgos sanitarios.",
                    },
                    {
                        "texto": "El municipio no tenía presupuesto propio para hacer estudios de agua ese trimestre.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio contextual: explica por qué el informe era útil, pero debe vincularse al deber ético del profesional.",
                    },
                ],
            },
            {
                "rival_falacia": {
                    "dialogo": "Durante cincuenta años esa mina operó sin que nadie denunciara arsénico; por lo tanto, es imposible que hoy exista contaminación en el agua.",
                    "es_falacia": True,
                    "tipo_argumento_rival": "FALACIA",
                    "nombre_falacia": "Apelación a la Tradición (Ad Antiquitatem)",
                    "explicacion_logica": "Asume que porque algo no se detectó en el pasado, no puede estar ocurriendo en el presente pese a las pruebas químicas.",
                },
                "rival_medio": {
                    "dialogo": "La divulgación abrupta del informe causó pánico financiero en los accionistas de la compañía antes de que pudieran aplicar un plan de remediación.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "MEDIO",
                    "nombre_falacia": None,
                    "explicacion_logica": "Señala un perjuicio económico real, pero subordinado frente a la prevención de envenenamiento por arsénico.",
                },
                "rival_infalible": {
                    "dialogo": "El protocolo pericial exige entregar simultáneamente el acta técnica a la autoridad ambiental y al responsable de seguridad industrial para detener el vertido de inmediato.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "INFALIBLE",
                    "nombre_falacia": None,
                    "explicacion_logica": "Argumento deontológico preciso sobre eficacia preventiva y notificación formal.",
                },
                "opciones": [
                    {
                        "texto": "Falsificar u ocultar un dictamen pericial constituiría perjurio técnico y complicidad en un daño ambiental irreversible contra la salud comunitaria.",
                        "tipo": "INFALIBLE",
                        "nombre_falacia": None,
                        "explicacion": "Argumento infalible: vincula la prohibición de falsedad ideológica con la responsabilidad social del perito.",
                    },
                    {
                        "texto": "Los directivos de las empresas mineras siempre mienten en todos los juicios, por eso su demanda carece de validez.",
                        "tipo": "FALACIA",
                        "nombre_falacia": "Generalización Apresurada / Ad Hominem",
                        "explicacion": "Falacia: descalifica mediante un estereotipo generalizado en lugar de probar la validez del actuar del perito.",
                    },
                    {
                        "texto": "El laboratorio donde se analizó el agua tenía equipos recién comprados este año.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: respalda la calidad técnica, pero no responde por sí mismo al dilema ético sobre el secreto profesional.",
                    },
                    {
                        "texto": "El perito intentó llamar por teléfono al gerente un viernes por la tarde antes de enviar el reporte.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: muestra cortesía profesional, aunque debe complementarse con el principio de supremacía de la salud pública.",
                    },
                ],
            },
        ],
    },
    {
        "id": "caso_auditoria_contable",
        "titulo": "Caso 3: La Auditoría de Fondos de Pensiones",
        "subtitulo": "Independencia Profesional y Conflicto de Interés",
        "abogado_rival": "Fiscal D. Sterling",
        "descripcion": (
            "Un auditor contable aprobó los balances de un fondo de pensiones donde su propio hermano "
            "era director financiero, ocultando pérdidas millonarias como 'inversiones estratégicas'. "
            "Tú representas al Comité de Ética que exige su sanción ejemplar."
        ),
        "turnos_banco": [
            {
                "rival_falacia": {
                    "dialogo": "Ustedes dicen que mi cliente tenía conflicto de interés por auditar a su hermano, ¡pero ustedes solo quieren destruir a la familia y prohibir que los hermanos se hablen!",
                    "es_falacia": True,
                    "tipo_argumento_rival": "FALACIA",
                    "nombre_falacia": "Hombre de Paja (Straw Man)",
                    "explicacion_logica": "Distorsiona la exigencia de independencia en auditoría convirtiéndola en una caricatura absurda contra la familia.",
                },
                "rival_medio": {
                    "dialogo": "Aunque eran hermanos, las operaciones contables siguieron plantillas estándar y no se demostró que el auditor recibiera sobornos directos.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "MEDIO",
                    "nombre_falacia": None,
                    "explicacion_logica": "Argumento medio: la ausencia de soborno no elimina el conflicto de interés objetivo ni el deber de abstención.",
                },
                "rival_infalible": {
                    "dialogo": "El auditor notificó por escrito su vínculo familiar al socio director de la firma auditora, quien aun así le ordenó firmar el dictamen bajo amenaza de despido.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "INFALIBLE",
                    "nombre_falacia": None,
                    "explicacion_logica": "Plantea un atenuante real sobre presión organizacional y reporte previo que exige un análisis ético riguroso.",
                },
                "opciones": [
                    {
                        "texto": "La independencia de criterio y apariencia es constitutiva de la fe pública del auditor: ante un vínculo familiar directo y presión indebida, el deber deontológico exige la excusación formal y negarse a firmar.",
                        "tipo": "INFALIBLE",
                        "nombre_falacia": None,
                        "explicacion": "Argumento infalible: fundamenta la función social de la fe pública, la objetividad e independencia como requisitos irrenunciables.",
                    },
                    {
                        "texto": "Nadie ha demostrado con certeza absoluta que todos los jubilados vayan a perder el 100% de sus ahorros mañana mismo.",
                        "tipo": "FALACIA",
                        "nombre_falacia": "Apelación a la Ignorancia (Ad Ignorantiam)",
                        "explicacion": "Falacia: exigir prueba de un colapso total inmediato para negar la falta ética ya consumada al falsear el balance.",
                    },
                    {
                        "texto": "El hermano del auditor ya tenía antecedentes de malas inversiones en empleos anteriores.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: contextualiza el riesgo, pero el núcleo ético es el deber de abstención y veracidad del auditor.",
                    },
                    {
                        "texto": "Las normas contables internacionales recomiendan rotar a los auditores cada cinco años.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: es verdadero, pero menos contundente que la incompatibilidad directa por parentesco y falsedad ideológica.",
                    },
                ],
            },
        ],
    },
    {
        "id": "caso_ia_periodismo",
        "titulo": "Caso 4: Fuentes Fabricadas con IA en Investigación",
        "subtitulo": "Ética Periodística, Rigor Documental y Deber de Veracidad",
        "abogado_rival": "Fiscal L. Valmont",
        "descripcion": (
            "Un periodista de investigación utilizó un generador de voz e imagen por IA para recrear "
            "declaraciones de un testigo anónimo sin advertir al público que eran sintéticas, "
            "provocando el cierre injusto de una cooperativa local."
        ),
        "turnos_banco": [
            {
                "rival_falacia": {
                    "dialogo": "¡Si le exigimos a este periodista que verifique cada fuente y etiquete el contenido generado por IA, entonces tendremos que prohibir la electricidad y volver a escribir en piedra!",
                    "es_falacia": True,
                    "tipo_argumento_rival": "FALACIA",
                    "nombre_falacia": "Reducción al Absurdo Falaz / Pendiente Resbaladiza",
                    "explicacion_logica": "Exagera grotescamente una norma básica de transparencia deontológica como si implicara rechazar toda la tecnología.",
                },
                "rival_medio": {
                    "dialogo": "El periodista usó la recreación sintética únicamente para proteger la identidad del informante frente a posibles represalias.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "MEDIO",
                    "nombre_falacia": None,
                    "explicacion_logica": "Proteger la fuente es legítimo, pero no justifica presentar material sintético como prueba documental real sin advertencia.",
                },
                "rival_infalible": {
                    "dialogo": "El editor jefe eliminó la marca de agua de advertencia de IA durante la edición final sin el consentimiento del reportero que entregó el borrador.",
                    "es_falacia": False,
                    "tipo_argumento_rival": "INFALIBLE",
                    "nombre_falacia": None,
                    "explicacion_logica": "Delimita con rigor la responsabilidad ética individual frente a la alteración editorial posterior.",
                },
                "opciones": [
                    {
                        "texto": "La deontología periodística exige transparencia radical con la audiencia y contraste independiente de hechos: proteger una fuente jamás autoriza presentar simulaciones sintéticas como evidencia fáctica sin rotulación explícita.",
                        "tipo": "INFALIBLE",
                        "nombre_falacia": None,
                        "explicacion": "Argumento infalible: articula el deber de veracidad, transparencia informativa y no engaño al ciudadano.",
                    },
                    {
                        "texto": "Ese periodista ganó un premio estudiantil hace diez años, así que es imposible que haya cometido un error ético hoy.",
                        "tipo": "FALACIA",
                        "nombre_falacia": "Apelación al Mérito Pasado / Ad Verecundiam",
                        "explicacion": "Falacia: los méritos pasados no eximen de evaluar objetivamente una vulneración ética actual.",
                    },
                    {
                        "texto": "El reportaje tuvo muchas visitas en internet y generó debate en la ciudad.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio: el impacto mediático no valida éticamente un método engañoso.",
                    },
                    {
                        "texto": "La cooperativa afectada tardó dos días en emitir su comunicado de desmentido.",
                        "tipo": "MEDIO",
                        "nombre_falacia": None,
                        "explicacion": "Argumento medio irrelevante para eximir al profesional de su deber previo de verificación.",
                    },
                ],
            }
        ],
    },
]


def generar_turno_respaldo_local(
    caso_id: str,
    dificultad: str,
    accion_jugador: str,
    declaracion_previa_rival: dict | None,
    opcion_elegida: dict | None,
    turno_idx: int,
) -> dict:
    """
    Genera una respuesta de turno instantánea en español siguiendo exactamente las reglas
    de dificultad cuando los proveedores gratuitos exceden el tiempo límite.
    """
    caso = next((c for c in CASOS_DISPONIBLES if c["id"] == caso_id), CASOS_DISPONIBLES[0])
    banco = caso["turnos_banco"]
    bloque = banco[turno_idx % len(banco)]

    dano_al_rival = 0
    dano_al_jugador = 0
    rival_detecto_falacia = False
    objecion_exitosa = None
    veredicto_juez = "El juicio da comienzo. ¡Escuchemos a las partes!"

    if accion_jugador == "MARCAR_FALACIA" and declaracion_previa_rival:
        era_falacia = bool(declaracion_previa_rival.get("es_falacia", False))
        explicacion_prev = declaracion_previa_rival.get("explicacion_logica", "")
        nombre_f = declaracion_previa_rival.get("nombre_falacia") or "Falacia lógica"
        if era_falacia:
            dano_al_rival = 25
            objecion_exitosa = True
            veredicto_juez = f"¡HA LUGAR! El rival cometió la falacia '{nombre_f}'. {explicacion_prev}"
        else:
            dano_al_jugador = 20
            objecion_exitosa = False
            veredicto_juez = f"¡NO HA LUGAR! El argumento del rival NO era una falacia. {explicacion_prev}"

    elif accion_jugador == "ARGUMENTAR" and opcion_elegida:
        tipo = opcion_elegida.get("tipo", "MEDIO")
        exp = opcion_elegida.get("explicacion", "")
        if tipo == "INFALIBLE":
            dano_al_rival = 25
            veredicto_juez = f"¡Argumento infalible! {exp}"
        elif tipo == "MEDIO":
            if dificultad == "FACIL":
                dano_al_jugador = 0
                veredicto_juez = f"Argumento parcial. {exp} El fiscal intenta responder pero duda."
            elif dificultad == "NORMAL":
                dano_al_jugador = 10
                veredicto_juez = f"Argumento vulnerable. {exp} El fiscal aprovecha el vacío lógico (-10 HP)."
            else:
                dano_al_jugador = 15
                veredicto_juez = f"Argumento insuficiente en dificultad Difícil. {exp} El fiscal contraataca con firmeza (-15 HP)."
        elif tipo == "FALACIA":
            prob_detectar = {"FACIL": 0.50, "NORMAL": 0.80, "DIFICIL": 0.95}.get(dificultad, 0.80)
            nom_fal = opcion_elegida.get("nombre_falacia") or "Falacia"
            if random.random() < prob_detectar:
                rival_detecto_falacia = True
                dano_al_jugador = 25
                veredicto_juez = f"¡El fiscal detectó tu falacia ({nom_fal})! {exp} (-25 HP)"
            else:
                veredicto_juez = f"Cometiste una falacia ({nom_fal}), ¡pero el fiscal no se dio cuenta esta vez!"

    r = random.random()
    if dificultad == "FACIL":
        eleccion_rival = bloque["rival_falacia"] if r < 0.60 else bloque["rival_medio"]
    elif dificultad == "NORMAL":
        if r < 0.35:
            eleccion_rival = bloque["rival_falacia"]
        elif r < 0.80:
            eleccion_rival = bloque["rival_medio"]
        else:
            eleccion_rival = bloque["rival_infalible"]
    else:
        if r < 0.18:
            eleccion_rival = bloque["rival_falacia"]
        elif r < 0.55:
            eleccion_rival = bloque["rival_medio"]
        else:
            eleccion_rival = bloque["rival_infalible"]

    opciones = [dict(op, id=i) for i, op in enumerate(bloque["opciones"])]
    random.shuffle(opciones)
    for idx, op in enumerate(opciones):
        op["id"] = idx

    return {
        "veredicto_juez": veredicto_juez,
        "dano_al_rival": dano_al_rival,
        "dano_al_jugador": dano_al_jugador,
        "rival_detecto_falacia_jugador": rival_detecto_falacia,
        "objecion_jugador_exitosa": objecion_exitosa,
        "declaracion_rival": eleccion_rival,
        "opciones_jugador": opciones,
    }
