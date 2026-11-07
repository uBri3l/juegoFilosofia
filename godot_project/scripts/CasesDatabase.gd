extends RefCounted
class_name CasesDatabase
## Base de datos completa de los 4 Casos de Ética Profesional integrada nativamente en Godot.
## Permite que el ejecutable (.exe / Web / Móvil) funcione en cualquier dispositivo
## sin necesidad de tener Python instalado, manteniendo todas las reglas de dificultad.

const CASOS: Dictionary = {
	"caso_algoritmo_medico": [
		{
			"rival_falacia": {
				"dialogo": "¡Señoría! La acusada lleva apenas dos años en la empresa y se viste de forma informal; alguien tan joven no puede entender de algoritmos médicos ni de ética corporativa.",
				"es_falacia": true,
				"tipo_argumento_rival": "FALACIA",
				"nombre_falacia": "Ad Hominem",
				"explicacion_logica": "Ataca la edad y vestimenta de la ingeniera en lugar de refutar la evidencia del sesgo del algoritmo."
			},
			"rival_medio": {
				"dialogo": "La ingeniera firmó libremente un contrato de confidencialidad (NDA). Cumplir la palabra empeñada y los contratos es un deber ético fundamental en cualquier profesión.",
				"es_falacia": false,
				"tipo_argumento_rival": "MEDIO",
				"nombre_falacia": null,
				"explicacion_logica": "Es un argumento válido en principio contractual, pero omite que ningún contrato privado está por encima de la vida humana."
			},
			"rival_infalible": {
				"dialogo": "Incluso ante un riesgo ético, los códigos deontológicos exigen agotar primero los canales internos de reporte de seguridad antes de exponer datos clínicos sensibles externamente.",
				"es_falacia": false,
				"tipo_argumento_rival": "INFALIBLE",
				"nombre_falacia": null,
				"explicacion_logica": "Argumento sólido de deontología profesional sobre el procedimiento gradual de denuncia responsable."
			},
			"opciones": [
				{
					"texto": "El código de ética de ingeniería prioriza la vida y seguridad pública sobre cualquier cláusula de confidencialidad privada cuando los reportes internos fueron ignorados.",
					"tipo": "INFALIBLE",
					"nombre_falacia": null,
					"explicacion": "Argumento infalible: aplica la jerarquía de deberes deontológicos (no maleficencia y bienestar público)."
				},
				{
					"texto": "El hospital tiene mucho dinero y seguro puede pagar una indemnización sin demandar a una trabajadora honesta.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: apela a la capacidad económica del hospital pero no resuelve el conflicto ético del NDA."
				},
				{
					"texto": "La ingeniera solo intentó ayudar porque sentía empatía por los pacientes mayores del hospital.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: la buena intención subjetiva atenúa la culpa, pero requiere sustento normativo objetivo."
				},
				{
					"texto": "Si castigamos a esta ingeniera hoy, mañana ningún médico ni ingeniero volverá a salvar una sola vida y colapsarán todos los hospitales del país.",
					"tipo": "FALACIA",
					"nombre_falacia": "Pendiente Resbaladiza",
					"explicacion": "Falacia de Pendiente Resbaladiza: encadena consecuencias extremas sin demostrar el nexo causal necesario."
				}
			]
		},
		{
			"rival_falacia": {
				"dialogo": "O protegemos absolutamente todos los secretos empresariales sin excepción, o destruimos por completo la industria tecnológica nacional. ¡No hay punto medio!",
				"es_falacia": true,
				"tipo_argumento_rival": "FALACIA",
				"nombre_falacia": "Falso Dilema",
				"explicacion_logica": "Presenta solo dos extremos radicales ignorando que se puede proteger la propiedad intelectual mientras se audita la seguridad médica."
			},
			"rival_medio": {
				"dialogo": "El algoritmo fue aprobado por el director comercial del hospital, por lo que la responsabilidad ética recaía únicamente en la gerencia y no en la programadora.",
				"es_falacia": false,
				"tipo_argumento_rival": "MEDIO",
				"nombre_falacia": null,
				"explicacion_logica": "Argumento parcial: aunque la gerencia es responsable, el profesional técnico no puede escudarse en la obediencia debida ante un daño directo."
			},
			"rival_infalible": {
				"dialogo": "La filtración incluyó registros sin anonimizar de tres pacientes reales, vulnerando el deber ético de privacidad médica que podía haberse evitado anonimizando la prueba.",
				"es_falacia": false,
				"tipo_argumento_rival": "INFALIBLE",
				"nombre_falacia": null,
				"explicacion_logica": "Señala con precisión un principio de proporcionalidad y minimización de daño en la revelación de pruebas."
			},
			"opciones": [
				{
					"texto": "La responsabilidad profesional no se anula por órdenes superiores: auditar y denunciar sesgos letales ante el regulador sanitario con datos minimizados cumple el principio de proporcionalidad.",
					"tipo": "INFALIBLE",
					"nombre_falacia": null,
					"explicacion": "Argumento infalible: integra autonomía moral del profesional, rechazo a la obediencia ciega y proporcionalidad ética."
				},
				{
					"texto": "Otros hospitales también usan algoritmos parecidos y nadie los ha auditado todavía.",
					"tipo": "FALACIA",
					"nombre_falacia": "Tu Quoque (Apelación a la práctica común)",
					"explicacion": "Falacia: que otros cometan la misma falta ética no convierte la práctica en moralmente aceptable."
				},
				{
					"texto": "El software tenía errores de programación que tarde o temprano iban a salir a la luz en la prensa.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: describe un hecho probable pero no fundamenta la legitimidad ética de la actuación profesional."
				},
				{
					"texto": "La ingeniera dejó constancia en un correo interno una semana antes de acudir al ministerio.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: aporta un hecho relevante pero requiere conectarlo con la urgencia del riesgo vital."
				}
			]
		}
	],
	"caso_vertido_quimico": [
		{
			"rival_falacia": {
				"dialogo": "El prestigioso Premio Nobel de Literatura afirmó hace años que la minería impulsa la cultura; por lo tanto, el informe químico de este perito sobre el arsénico es falso.",
				"es_falacia": true,
				"tipo_argumento_rival": "FALACIA",
				"nombre_falacia": "Apelación a la Autoridad Irrelevante (Ad Verecundiam)",
				"explicacion_logica": "Cita a una autoridad ajena al campo científico para refutar un análisis químico toxicológico."
			},
			"rival_medio": {
				"dialogo": "El cliente pagó los honorarios del estudio privado, de modo que los resultados pertenecen exclusivamente a la empresa contratante.",
				"es_falacia": false,
				"tipo_argumento_rival": "MEDIO",
				"nombre_falacia": null,
				"explicacion_logica": "Argumento patrimonial ordinario, pero refutable porque la propiedad de un estudio no autoriza ocultar un peligro inminente para terceros."
			},
			"rival_infalible": {
				"dialogo": "El perito debía certificar la contramuestra con un segundo laboratorio acreditado antes de declarar la emergencia pública, asegurando rigor metodológico.",
				"es_falacia": false,
				"tipo_argumento_rival": "INFALIBLE",
				"nombre_falacia": null,
				"explicacion_logica": "Argumento sólido basado en el deber de diligencia científica y verificación técnica."
			},
			"opciones": [
				{
					"texto": "La veracidad científica y la protección de terceros frente a un riesgo tóxico inminente son deberes inalienables que prevalecen sobre el interés comercial del cliente.",
					"tipo": "INFALIBLE",
					"nombre_falacia": null,
					"explicacion": "Argumento infalible: aplica los principios de integridad científica, no maleficencia y límite ético del secreto profesional."
				},
				{
					"texto": "Todo el pueblo cree en redes sociales que la minera es culpable, así que el perito tenía toda la razón desde el principio.",
					"tipo": "FALACIA",
					"nombre_falacia": "Ad Populum (Apelación a la mayoría)",
					"explicacion": "Falacia Ad Populum: la validez de un hallazgo químico depende de la evidencia empírica, no de la opinión popular."
				},
				{
					"texto": "El perito cobró menos de lo habitual por ese informe, lo que demuestra su desinterés económico.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: habla bien de su motivación, pero es secundario frente a la obligación deontológica."
				},
				{
					"texto": "El municipio no tenía presupuesto propio para hacer estudios de agua ese trimestre.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio contextual: explica por qué el informe era útil, pero debe vincularse al deber ético del profesional."
				}
			]
		}
	],
	"caso_auditoria_contable": [
		{
			"rival_falacia": {
				"dialogo": "Ustedes dicen que mi cliente tenía conflicto de interés por auditar a su hermano, ¡pero ustedes solo quieren destruir a la familia y prohibir que los hermanos se hablen!",
				"es_falacia": true,
				"tipo_argumento_rival": "FALACIA",
				"nombre_falacia": "Hombre de Paja (Straw Man)",
				"explicacion_logica": "Distorsiona la exigencia de independencia en auditoría convirtiéndola en una caricatura absurda contra la familia."
			},
			"rival_medio": {
				"dialogo": "Aunque eran hermanos, las operaciones contables siguieron plantillas estándar y no se demostró que el auditor recibiera sobornos directos.",
				"es_falacia": false,
				"tipo_argumento_rival": "MEDIO",
				"nombre_falacia": null,
				"explicacion_logica": "Argumento medio: la ausencia de soborno no elimina el conflicto de interés objetivo ni el deber de abstención."
			},
			"rival_infalible": {
				"dialogo": "El auditor notificó por escrito su vínculo familiar al socio director de la firma auditora, quien aun así le ordenó firmar el dictamen bajo amenaza de despido.",
				"es_falacia": false,
				"tipo_argumento_rival": "INFALIBLE",
				"nombre_falacia": null,
				"explicacion_logica": "Plantea un atenuante real sobre presión organizacional y reporte previo que exige un análisis ético riguroso."
			},
			"opciones": [
				{
					"texto": "La independencia de criterio y apariencia es constitutiva de la fe pública del auditor: ante un vínculo familiar directo y presión indebida, el deber deontológico exige la excusación formal y negarse a firmar.",
					"tipo": "INFALIBLE",
					"nombre_falacia": null,
					"explicacion": "Argumento infalible: fundamenta la función social de la fe pública, la objetividad e independencia como requisitos irrenunciables."
				},
				{
					"texto": "Nadie ha demostrado con certeza absoluta que todos los jubilados vayan a perder el 100% de sus ahorros mañana mismo.",
					"tipo": "FALACIA",
					"nombre_falacia": "Apelación a la Ignorancia (Ad Ignorantiam)",
					"explicacion": "Falacia: exigir prueba de un colapso total inmediato para negar la falta ética ya consumada al falsear el balance."
				},
				{
					"texto": "El hermano del auditor ya tenía antecedentes de malas inversiones en empleos anteriores.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: contextualiza el riesgo, pero el núcleo ético es el deber de abstención y veracidad del auditor."
				},
				{
					"texto": "Las normas contables internacionales recomiendan rotar a los auditores cada cinco años.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: es verdadero, pero menos contundente que la incompatibilidad directa por parentesco."
				}
			]
		}
	],
	"caso_ia_periodismo": [
		{
			"rival_falacia": {
				"dialogo": "¡Si le exigimos a este periodista que verifique cada fuente y etiquete el contenido generado por IA, entonces tendremos que prohibir la electricidad y volver a escribir en piedra!",
				"es_falacia": true,
				"tipo_argumento_rival": "FALACIA",
				"nombre_falacia": "Reducción al Absurdo Falaz / Pendiente Resbaladiza",
				"explicacion_logica": "Exagera grotescamente una norma básica de transparencia deontológica como si implicara rechazar toda la tecnología."
			},
			"rival_medio": {
				"dialogo": "El periodista usó la recreación sintética únicamente para proteger la identidad del informante frente a posibles represalias.",
				"es_falacia": false,
				"tipo_argumento_rival": "MEDIO",
				"nombre_falacia": null,
				"explicacion_logica": "Proteger la fuente es legítimo, pero no justifica presentar material sintético como prueba documental real sin advertencia."
			},
			"rival_infalible": {
				"dialogo": "El editor jefe eliminó la marca de agua de advertencia de IA durante la edición final sin el consentimiento del reportero que entregó el borrador.",
				"es_falacia": false,
				"tipo_argumento_rival": "INFALIBLE",
				"nombre_falacia": null,
				"explicacion_logica": "Delimita con rigor la responsabilidad ética individual frente a la alteración editorial posterior."
			},
			"opciones": [
				{
					"texto": "La deontología periodística exige transparencia radical con la audiencia y contraste independiente de hechos: proteger una fuente jamás autoriza presentar simulaciones sintéticas como evidencia fáctica sin rotulación explícita.",
					"tipo": "INFALIBLE",
					"nombre_falacia": null,
					"explicacion": "Argumento infalible: articula el deber de veracidad, transparencia informativa y no engaño al ciudadano."
				},
				{
					"texto": "Ese periodista ganó un premio estudiantil hace diez años, así que es imposible que haya cometido un error ético hoy.",
					"tipo": "FALACIA",
					"nombre_falacia": "Apelación al Mérito Pasado",
					"explicacion": "Falacia: los méritos pasados no eximen de evaluar objetivamente una vulneración ética actual."
				},
				{
					"texto": "El reportaje tuvo muchas visitas en internet y generó debate en la ciudad.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio: el impacto mediático no valida éticamente un método engañoso."
				},
				{
					"texto": "La cooperativa afectada tardó dos días en emitir su comunicado de desmentido.",
					"tipo": "MEDIO",
					"nombre_falacia": null,
					"explicacion": "Argumento medio irrelevante para eximir al profesional de su deber previo de verificación."
				}
			]
		}
	]
}


static func generar_turno_autonomo(
	caso_id: String,
	dificultad: String,
	accion: String,
	declaracion_previa: Dictionary,
	opcion_elegida: Dictionary,
	turno_idx: int
) -> Dictionary:
	var lista_turnos: Array = CASOS.get(caso_id, CASOS["caso_algoritmo_medico"])
	var bloque: Dictionary = lista_turnos[turno_idx % lista_turnos.size()]

	var dano_r: int = 0
	var dano_j: int = 0
	var detecto_falacia: bool = false
	var veredicto: String = "El juicio da comienzo. ¡Escuchemos a las partes!"

	if accion == "MARCAR_FALACIA" and not declaracion_previa.is_empty():
		var era_fal: bool = bool(declaracion_previa.get("es_falacia", false))
		var exp_prev: String = str(declaracion_previa.get("explicacion_logica", ""))
		var nom_f: String = str(declaracion_previa.get("nombre_falacia", "Falacia lógica"))
		if era_fal:
			dano_r = 25
			veredicto = "¡HA LUGAR! El rival cometió la falacia '%s'. %s" % [nom_f, exp_prev]
		else:
			dano_j = 20
			veredicto = "¡NO HA LUGAR! El argumento del rival NO era una falacia. %s" % exp_prev
	elif accion == "ARGUMENTAR" and not opcion_elegida.is_empty():
		var t: String = str(opcion_elegida.get("tipo", "MEDIO"))
		var exp: String = str(opcion_elegida.get("explicacion", ""))
		if t == "INFALIBLE":
			dano_r = 25
			veredicto = "¡Argumento infalible! " + exp
		elif t == "FALACIA":
			var prob_det: float = 0.50 if dificultad == "FACIL" else (0.80 if dificultad == "NORMAL" else 0.95)
			var nom_fal: String = str(opcion_elegida.get("nombre_falacia", "Falacia"))
			if randf() < prob_det:
				detecto_falacia = true
				dano_j = 25
				veredicto = "¡El fiscal detectó tu falacia (%s)! %s (-25 HP)" % [nom_fal, exp]
			else:
				veredicto = "Cometiste una falacia (%s), ¡pero el fiscal no se dio cuenta esta vez!" % nom_fal
		else:
			if dificultad == "FACIL":
				dano_j = 0
				veredicto = "Argumento parcial. " + exp
			elif dificultad == "NORMAL":
				dano_j = 10
				veredicto = "Argumento vulnerable. %s (-10 HP)." % exp
			else:
				dano_j = 15
				veredicto = "Argumento insuficiente en dificultad Difícil. %s (-15 HP)." % exp

	var r: float = randf()
	var eleccion_rival: Dictionary
	if dificultad == "FACIL":
		eleccion_rival = bloque["rival_falacia"] if r < 0.60 else bloque["rival_medio"]
	elif dificultad == "NORMAL":
		eleccion_rival = bloque["rival_falacia"] if r < 0.35 else (bloque["rival_medio"] if r < 0.80 else bloque["rival_infalible"])
	else:
		eleccion_rival = bloque["rival_falacia"] if r < 0.18 else (bloque["rival_medio"] if r < 0.55 else bloque["rival_infalible"])

	var nuevas_opciones: Array = []
	for op in bloque["opciones"]:
		nuevas_opciones.append(op.duplicate())
	nuevas_opciones.shuffle()

	return {
		"modelo_usado": "Motor-Autónomo-MultiDispositivo",
		"veredicto_juez": veredicto,
		"dano_al_rival": dano_r,
		"dano_al_jugador": dano_j,
		"rival_detecto_falacia_jugador": detecto_falacia,
		"declaracion_rival": eleccion_rival,
		"opciones_jugador": nuevas_opciones
	}
