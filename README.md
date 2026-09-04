# Run Coach

Een hardloop coach app die je snelheid, tijd en locatie bijhoudt tijdens het hardlopen. De app slaat ook je hardloopgeschiedenis op.

## Functionaliteiten

- **Real-time tracking**: Volg je afstand, snelheid, tempo en tijd tijdens het hardlopen
- **GPS locatie**: Nauwkeurige locatietracking met GPS
- **Geschiedenis**: Bekijk al je eerdere hardloopsessies
- **Statistieken**: Bekijk je totale afstand, gemiddelde snelheid en meer
- **Audio feedback**: Optionele stemfeedback tijdens het hardlopen
- **Deel je runs**: Deel je hardloopresultaten met vrienden

## Schermen

### Home Scherm
- Snelle toegang tot starten van een nieuwe run
- Overzicht van je totale statistieken
- Recentste runs
- Toegang tot geschiedenis en instellingen

### Run Scherm
- Real-time weergave van:
  - Afstand
  - Tijd
  - Huidige snelheid
  - Huidig tempo
  - Gemiddelde snelheid
  - Gemiddeld tempo
  - Maximale snelheid
- Pauzeer en hervat je run
- Milestone tracking (5K, 10K, halve marathon, marathon)

### Geschiedenis Scherm
- Overzicht van alle eerdere runs
- Filter opties (deze maand, deze week, langer dan 5km, etc.)
- Sorteer opties (datum, afstand, snelheid)
- Klik op een run voor gedetailleerde informatie

### Samenvatting Scherm
- Gedetailleerde weergave van een afgeronde run
- Alle statistieken op een rij
- Deel knop om je resultaat te delen

### Instellingen Scherm
- Donkere modus
- Audio feedback in/uit
- Eenheden (km/mi)
- Data beheer (exporteren, wissen)
- App informatie

## Installatie

### Voor Android

1. Zorg dat je Flutter omgeving is ingesteld:
   ```bash
   flutter doctor
   ```

2. Navigeer naar de projectmap:
   ```bash
   cd RunCoach
   ```

3. Haal de afhankelijkheden op:
   ```bash
   flutter pub get
   ```

4. Bouw en installeer op je Android apparaat:
   ```bash
   flutter run
   ```

5. Voor een release build:
   ```bash
   flutter build apk --release
   ```
   De APK vind je in: `build/app/outputs/flutter-apk/app-release.apk`

### Voor iOS

1. Navigeer naar de projectmap:
   ```bash
   cd RunCoach
   ```

2. Haal de afhankelijkheden op:
   ```bash
   flutter pub get
   ```

3. Installeer CocoaPods:
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. Bouw en installeer op je iOS apparaat:
   ```bash
   flutter run
   ```

5. Voor een release build:
   ```bash
   flutter build ios --release
   ```

## Benodigde Permissies

### Android
- `ACCESS_FINE_LOCATION`: Voor nauwkeurige locatietracking
- `ACCESS_COARSE_LOCATION`: Voor algemene locatietracking
- `ACCESS_BACKGROUND_LOCATION`: Voor tracking op de achtergrond
- `FOREGROUND_SERVICE`: Voor de tracking service

### iOS
- `NSLocationWhenInUseUsageDescription`: Locatie toegang tijdens gebruik
- `NSLocationAlwaysAndWhenInUseUsageDescription`: Locatie toegang altijd en tijdens gebruik
- `UIBackgroundModes`: Achtergrond modus voor locatie updates

## Project Structuur

```
lib/
├── main.dart              # App entry point
├── app.dart               # App configuratie
├── models/
│   └── run_session.dart   # Data modellen voor runs
├── providers/
│   └── run_provider.dart  # State management met Riverpod
├── services/
│   ├── location_service.dart    # GPS locatie service
│   ├── storage_service.dart     # Data opslag service
│   └── audio_feedback_service.dart # Audio feedback service
├── screens/
│   ├── home_screen.dart          # Home scherm
│   ├── run_screen.dart           # Actieve run scherm
│   ├── run_summary_screen.dart   # Run samenvatting scherm
│   ├── history_screen.dart       # Geschiedenis scherm
│   └── settings_screen.dart      # Instellingen scherm
└── widgets/
    ├── stat_card.dart            # Statistiek kaart widget
    ├── stat_display.dart         # Statistiek weergave widget
    └── run_action_button.dart     # Run actie knop widget
```

## Afhankelijkheden

De app gebruikt de volgende Flutter packages:

- `flutter_riverpod`: State management
- `go_router`: Navigatie
- `geolocator`: GPS locatie tracking
- `path_provider`: Toegang tot opslag locaties
- `shared_preferences`: Eenvoudige opslag van instellingen
- `intl`: Datum en tijd formatting
- `share_plus`: Delen van run resultaten

Zie `pubspec.yaml` voor de complete lijst met versies.

## Problemen Oplossen

### Locatie toegang
Als de app geen locatie kan verkrijgen:
1. Controleer of locatie services zijn ingeschakeld op je apparaat
2. Controleer of de app locatie toegang heeft in de instellingen
3. Start de app opnieuw

### Build fouten
Als je build fouten krijgt:
1. Voer `flutter clean` uit
2. Voer `flutter pub get` uit
3. Probeer opnieuw te bouwen

### Android specifieke problemen
Voor Android 10+:
- Zorg dat je `minSdkVersion` minimaal 21 is
- Voeg achtergrond locatie toegang toe in `AndroidManifest.xml`

### iOS specifieke problemen
Voor iOS:
- Zorg dat je Info.plist de juiste locatie beschrijvingen heeft
- Voeg achtergrond modus toe voor locatie updates

## Bijdragen

Bijdragen zijn welkom! Open een pull request met je wijzigingen.

## Licentie

Deze app is ontwikkeld voor persoonlijk gebruik.

---

**Run Coach - Jouw persoonlijke hardloop coach!**
