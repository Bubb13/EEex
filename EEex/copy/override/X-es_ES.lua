
----------------------------
-- Miscellaneous Keybinds --
----------------------------

uiStrings["EEex_Options_TRANSLATION_Keybinds_TabTitle"] = "Atajos de teclado varios"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions"] = "Abrir opciones"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions_Description"] = [[
Tecla de acceso rápido que permite acceder rápidamente a este menú.
]]

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput"] = "Activar/desactivar salida código de tecla"

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput_Description"] = [[
Esta combinación de teclas activa o desactiva la salida del código de tecla.

Cuando está activada, cada vez que se pulse una tecla, EEex mostrará el código de tecla pulsada en el registro de combate.
]]

-------------
-- Modules --
-------------

uiStrings["EEex_Options_TRANSLATION_Modules_TabTitle"] = "Módulos"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu"] = "Habilitar módulo de menú de efectos"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu_Description"] = [[
Habilita el menú de efectos.

Se puede abrir un menú que muestra todos los hechizos que afectan actualmente a una criatura manteniendo pulsada una tecla de acceso rápido (por defecto, la tecla "Mayús" izquierda) y pasando el cursor por encima de dicha criatura.

Ten en cuenta que este menú se genera dinámicamente: hace lo mejor que puede, aunque hay lagunas en lo que puede detectar y, en ocasiones, puede mostrar hechizos internos.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer"] = "Habilitar el módulo de contenedores vacíos"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer_Description"] = [[
Cambia el color de resaltado de los contenedores vacíos a gris (en lugar del cian habitual).
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule"] = "Habilitar módulo de escala"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule_Description"] = [[
Habilita la posibilidad de establecer el factor de escala de la interfaz de usuario en un valor personalizado.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep"] = "Habilitar módulo de avance de tiempo"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep_Description"] = [[
Habilita una tecla de acceso rápido (por defecto, "D") que, cuando el juego está en pausa, hace avanzar el tiempo en la cantidad mínima.

Básicamente, la combinación de teclas hace que el juego se reanude y se vuelva a pausar muy rápidamente.

Si se mantiene pulsada la combinación de teclas durante medio segundo, el tiempo fluye hasta que se suelta.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule"] = "Habilitar módulo de temporizadores"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule_Description"] = [[
Habilita indicadores visuales junto a los retratos de los miembros del grupo que muestran diversa información sobre los temporizadores.
]]

-------------------------
-- Module: Effect Menu --
-------------------------

uiStrings["EEex_Options_TRANSLATION_EffectMenu_TabTitle"] = "Módulo: Menú de efectos"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind"] = "Atajo de teclado para abrir"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind_Description"] = [[
El menú de efectos se abre al mantener pulsada esta tecla y pasar el ratón por encima de una criatura.
]]

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount"] = "Número de filas"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount_Description"] = [[
El número de filas que muestra el menú emergente de efectos.
]]

-------------------
-- Module: Scale --
-------------------

uiStrings["EEex_Options_TRANSLATION_Scale_TabTitle"] = "Módulo: Escala"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage"] = "Porcentaje de escala [0-1]"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage_Description"] = [[
Obliga al motor a utilizar el factor de escala de la interfaz de usuario proporcionado.

Este campo es un número decimal entre 0 y 1.

Por ejemplo, un valor de "0,5" obligaría al juego a utilizar un factor de escala del 50 %.
]]

-----------------------
-- Module: Time Step --
-----------------------

uiStrings["EEex_Options_TRANSLATION_TimeStep_TabTitle"] = "Módulo: Avance de tiempo"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind"] = "Atajo de teclado para avanzar en el tiempo"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind_Description"] = [[
Cuando el juego está en pausa, esta combinación de teclas hace avanzar el tiempo en la cantidad mínima.

Básicamente, la combinación de teclas hace que el juego se reanude y vuelva a pausarse muy rápidamente.

Si se mantiene pulsada la combinación de teclas durante medio segundo, el tiempo fluye hasta que se suelta.
]]

-------------------
-- Module: Timer --
-------------------

uiStrings["EEex_Options_TRANSLATION_Timer_TabTitle"] = "Módulo: Temporizadores"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits"] = "Abrazar retratos"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits_Description"] = [[
Elimina el espacio entre las barras de los temporizadores y sus respectivos retratos.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer"] = "Mostrar temporizador de lanzamiento"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer_Description"] = [[
Activa una barra de color cian junto a los retratos de los miembros del grupo.

Este indicador muestra el tiempo de recarga para el uso de conjuros y objetos.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer"] = "Mostrar temporizador de contingencias"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer_Description"] = [[
Activa una barra verde junto a los retratos de los miembros del grupo.

Este indicador muestra el intervalo en el que se comprueban las condiciones de contingencia.

Ten en cuenta que algunos mods añaden efectos de contingencia en segundo plano para implementar ciertos comportamientos; esto puede hacer que el indicador de contingencia aparezca de forma inesperada.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer"] = "Mostrar temporizador modal"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer_Description"] = [[
Activa una barra roja junto a los retratos de los miembros del grupo.

Este indicador muestra el intervalo de las acciones modales: detectar trampas, expulsar a los no muertos, etc.
]]

---------------
-- Uncap FPS --
---------------

uiStrings["EEex_Options_TRANSLATION_UncapFPS_TabTitle"] = "Desbloquear FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed"] = "Velocidad IA"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed_Description"] = [[
El número de veces por segundo que se ejecuta la "lógica" del juego.

Esto determina la velocidad del juego.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_BusyWaitThreshold"] = "Umbral de espera activa"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_BusyWaitThreshold_Description"] = [[
Si el siguiente fotograma está programado dentro de este número de milisegundos, el motor espera en espera activa en lugar de ceder la CPU.

Solo está activo cuando la opción "Habilitar desbloqueo de FPS" está activada.

Los valores más altos mejoran el ritmo de los fotogramas a costa de un mayor uso de la CPU.

Un valor de «0» desactiva la cesión. No utilices esto a menos que estés jugando en un dispositivo de muy baja potencia.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable"] = "Habilitar desbloqueo de FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable_Description"] = [[
Elimina el límite habitual de 30 fps del motor, lo que permite que el juego se renderice a la frecuencia de actualización de tu monitor.

Esto mejora la fluidez del movimiento de la ventana de visualización en monitores con una alta frecuencia de actualización.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit"] = "Límite de FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit_Description"] = [[
Limita los FPS sin límite al valor indicado.

Esto no puede reducir los FPS por debajo del valor de la opción "Velocidad IA".
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier"] = "Eliminar multiplicador desplazamiento del botón central del ratón "

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier_Description"] = [[
Elimina el multiplicador fijo aplicado al movimiento de la ventana de visualización que se realiza al mantener pulsado el botón central del ratón.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled"] = "VSync habilitado"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled_Description"] = [[
Controla si el motor sincroniza automáticamente la frecuencia de renderizado del juego con el monitor.

Esto elimina el tearing de la pantalla a costa de una mayor latencia de entrada.
]]

-------------------
-- Miscellaneous --
-------------------

uiStrings["B3EffectMenu_TRANSLATION_No_Name"]              = "(Sin nombre)"
uiStrings["EEex_Options_TRANSLATION_Accept"]               = "Aceptar"
uiStrings["EEex_Options_TRANSLATION_EEex_Options"]         = "Opciones EEex"
uiStrings["EEex_Options_TRANSLATION_Exit"]                 = "Salir"
uiStrings["EEex_Options_TRANSLATION_Locked"]               = "(Bloqueado)"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Pressed"]  = "Al pulsar secuencia"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Released"] = "Al soltar secuencia"
uiStrings["EEex_Options_TRANSLATION_Requires_Restart"]     = "Requiere reinicio"
uiStrings["EEex_Options_TRANSLATION_Reset_to_Default"]     = "Restablecer valores predeterminados"

uiStrings["EEex_Options_TRANSLATION_Description_Hint"] = [[
Clic en el nombre de una opción para ver su descripción.
]]
