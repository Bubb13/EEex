
----------------------------
-- Miscellaneous Keybinds --
----------------------------

uiStrings["EEex_Options_TRANSLATION_Keybinds_TabTitle"] = "Tasti rapidi vari"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions"] = "Apri opzioni"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions_Description"] = [[
Tasto rapido che consente di accedere velocemente a questo menu.
]]

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput"] = "Output codici dei tasti"

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput_Description"] = [[
Questo tasto rapido attiva o disattiva la stampa dei codici dei tasti.

Quando è abilitato, ogni volta che premi un tasto EEex scriverà nel registro di combattimento il codice del tasto premuto.
]]

-------------
-- Modules --
-------------

uiStrings["EEex_Options_TRANSLATION_Modules_TabTitle"] = "Moduli"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu"] = "Abilita modulo menu effetti"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu_Description"] = [[
Abilita il menu degli effetti.

È possibile richiamare un menu che mostra tutti i buff/debuff che influenzano attualmente una creatura tenendo premuto un tasto rapido (per impostazione predefinita 'Maiusc sinistro') e passando il mouse su quella creatura.

Nota che questo menu viene generato dinamicamente: il rilevamento è il più accurato possibile, ma non copre tutti i casi e a volte può mostrare informazioni usate internamente dal gioco.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer"] = "Abilita modulo contenitori vuoti"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer_Description"] = [[
Cambia in grigio il colore di evidenziazione dei contenitori vuoti (sostituendo il normale ciano).
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule"] = "Abilita modulo ridimensionamento"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule_Description"] = [[
Abilita la possibilità di impostare un valore personalizzato per il fattore di scala dell'interfaccia.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep"] = "Abilita modulo avanzamento tempo"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep_Description"] = [[
Abilita un tasto rapido (per impostazione predefinita 'D') che, quando il gioco è in pausa, fa avanzare il tempo della minima quantità possibile.

In pratica, il tasto rapido fa uscire il gioco dalla pausa e lo rimette in pausa quasi istantaneamente.

Tenendo premuto il tasto rapido per mezzo secondo, il tempo scorre finché non viene rilasciato.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule"] = "Abilita modulo timer"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule_Description"] = [[
Abilita indicatori visivi accanto ai ritratti dei membri del gruppo che mostrano varie informazioni sui timer.
]]

-------------------------
-- Module: Effect Menu --
-------------------------

uiStrings["EEex_Options_TRANSLATION_EffectMenu_TabTitle"] = "Modulo: menu effetti"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind"] = "Tasto rapido di apertura"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind_Description"] = [[
Il menu effetti viene aperto quando questo tasto rapido è tenuto premuto e il mouse passa sopra una creatura.
]]

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount"] = "Numero di righe"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount_Description"] = [[
Numero di righe visualizzate dal popup del menu effetti.
]]

-------------------
-- Module: Scale --
-------------------

uiStrings["EEex_Options_TRANSLATION_Scale_TabTitle"] = "Modulo: ridimensionamento"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage"] = "Fattore di scala [0-1]"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage_Description"] = [[
Forza il motore di gioco a usare il fattore di scala dell'interfaccia fornito.

Questo campo è un numero decimale compreso tra 0 e 1.

Ad esempio, il valore '0.5' costringe il gioco a usare un fattore di scala del 50%.
]]

-----------------------
-- Module: Time Step --
-----------------------

uiStrings["EEex_Options_TRANSLATION_TimeStep_TabTitle"] = "Modulo: avanzamento tempo"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind"] = "Tasto rapido avanzamento tempo"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind_Description"] = [[
Quando il gioco è in pausa, questo tasto rapido fa avanzare il tempo della minima quantità possibile.

In pratica, il tasto rapido fa uscire il gioco dalla pausa e lo rimette in pausa quasi istantaneamente.

Tenendo premuto il tasto rapido per mezzo secondo, il tempo scorre finché non viene rilasciato.
]]

-------------------
-- Module: Timer --
-------------------

uiStrings["EEex_Options_TRANSLATION_Timer_TabTitle"] = "Modulo: timer"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits"] = "Barre aderenti ai ritratti"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits_Description"] = [[
Rimuove lo spazio tra le barre timer e il rispettivo ritratto.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer"] = "Mostra timer di lancio"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer_Description"] = [[
Abilita una barra ciano accanto ai ritratti dei membri del gruppo.

Questo indicatore mostra il tempo di recupero per usare incantesimi/oggetti.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer"] = "Mostra timer delle contingenze"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer_Description"] = [[
Abilita una barra verde accanto ai ritratti dei membri del gruppo.

Questo indicatore mostra l'intervallo con cui vengono verificate le condizioni di contingenza.

Nota che alcune mod aggiungono effetti di contingenza interni (noti come 'Dietro le Quinte') per implementare determinati comportamenti: questo può far comparire inaspettatamente l'indicatore di contingenza.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer"] = "Mostra timer delle azioni modali"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer_Description"] = [[
Abilita una barra rossa accanto ai ritratti dei membri del gruppo.

Questo indicatore mostra l'intervallo delle azioni modali: individuare trappole, scacciare non morti, ecc.
]]

---------------
-- Uncap FPS --
---------------

uiStrings["EEex_Options_TRANSLATION_UncapFPS_TabTitle"] = "Sblocca FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed"] = "Velocità IA"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed_Description"] = [[
Numero di volte al secondo in cui viene eseguita la "logica" del gioco.

Determina la velocità di gioco.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable"] = "Abilita sblocco FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable_Description"] = [[
Rimuove il consueto limite di 30 FPS del motore di gioco, consentendo a quest'ultimo di renderizzare alla frequenza di aggiornamento del monitor.

Migliora la fluidità dello spostamento della visuale sui monitor ad alta frequenza di aggiornamento.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_EnableFPSLimit"] = "Abilita limite FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_EnableFPSLimit_Description"] = [[
Abilita l'opzione "Limite FPS".

Per un'esperienza più fluida, lascia questa opzione disabilitata e abilita VSync oppure limita gli FPS del gioco tramite le impostazioni del driver grafico.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit"] = "Limite FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit_Description"] = [[
Limita gli FPS sbloccati al valore indicato.

Non può ridurre gli FPS al di sotto dell'opzione "Velocità IA".
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimitBusyWaitThreshold"] = "Soglia di attesa attiva del limite FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimitBusyWaitThreshold_Description"] = [[
Se il prossimo frame è programmato entro questo numero di millisecondi, il motore di gioco resta in attesa attiva
invece di cedere il controllo della CPU.

Attiva solo quando le opzioni "Abilita sblocco FPS" e "Abilita limite FPS" sono abilitate.

Valori più alti migliorano la regolarità dei frame al costo di un maggiore uso della CPU.

Il valore '0' disabilita la cessione della CPU. Non usarlo a meno che tu non stia giocando su un dispositivo estremamente poco potente.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_LuaGCSteps"] = "Fasi di Garbage Collection di Lua"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_LuaGCSteps_Description"] = [[
Determina quanto tempo Lua dedica a liberare memoria non più usata dopo ogni frame.

Valori più bassi producono FPS più alti, ma possono causare scatti a causa dell'accumulo nel tempo di grandi quantità di dati inutilizzati.

Valori più alti prevengono gli scatti al costo di ridurre gli FPS.

Valori estremamente alti possono richiedere troppo tempo e compromettere la regolarità dei frame.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier"] = "Rimuovi moltiplicatore del pulsante centrale del mouse"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier_Description"] = [[
Rimuove il moltiplicatore codificato applicato allo spostamento della visuale effettuato tenendo premuto il pulsante centrale del mouse.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled"] = "VSync abilitato"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled_Description"] = [[
Controlla se il motore di gioco sincronizza automaticamente la frequenza di rendering del gioco con il monitor.

Elimina il tearing dello schermo al costo di una maggiore latenza di input.
]]

-------------------
-- Miscellaneous --
-------------------

uiStrings["B3EffectMenu_TRANSLATION_No_Name"]              = "(Senza nome)"
uiStrings["EEex_Options_TRANSLATION_Accept"]               = "Accetta"
uiStrings["EEex_Options_TRANSLATION_EEex_Options"]         = "Opzioni EEex"
uiStrings["EEex_Options_TRANSLATION_Exit"]                 = "Esci"
uiStrings["EEex_Options_TRANSLATION_Locked"]               = "(Bloccato)"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Pressed"]  = "Alla pressione della sequenza"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Released"] = "Al rilascio della sequenza"
uiStrings["EEex_Options_TRANSLATION_Requires_Restart"]     = "Richiede il riavvio"
uiStrings["EEex_Options_TRANSLATION_Reset_to_Default"]     = "Ripristina valore predefinito"

uiStrings["EEex_Options_TRANSLATION_Description_Hint"] = [[
Fai clic sul nome di un'opzione per visualizzarne la descrizione.
]]
