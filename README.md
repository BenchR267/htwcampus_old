## htwcampus
Dies wird die erste offizielle iOS-App der HTW Dresden.

In der finalen Version wird man damit folgendes können:

- Stundenplan einsehen
- Notenspiegel einsehen
- Raumplanung einsehen
- Prüfungsplan einsehen
- Mensapläne einsehen
- evtl einen Lageplan der HTW Dresden einsehen
- evtl eine Startseite als Begrüßung mit wichtigsten Details
- evtl Bibliothek

## Aktueller Fortschritt

- Stundenplan funktioniert für Studenten und Dozenten
	- incl Bearbeitung dessen (Editieren, Löschen, Hinzufügen und Ausblenden)
	- mehrere Stundenpläne möglich
	- Export des gesamten Stundenplans eines Nutzers oder einer einzelnen Stunde direkt möglich
- Raumplanung mittels "Überwachung"
	- Es können Räume aus einer Liste ausgewählt werden, welche einmalig über CoreData gespeichert werden und dann überwacht werden
- Prüfungsplaner
	- Es können alle Prüfungen eines Studiengangs oder eines Prüfenden angezeigt werden
	- Einzelne Prüfungen können in einen ausgewählten Stundenplan übertragen werden und so dort angezeigt werden
- Noten können eingesehen werden
	- Notendurchschnitt wird automatisch berechnet
	- Login kann, muss aber nicht gespeichert werden
	- Noten werden nach Semestern absteigend sortiert (neue zuerst)
- Mensenpläne können eingesehen werden
	- 17 Mensen werden abgefragt
	- für Details wird die Seite des Studentenwerks geöffnet
