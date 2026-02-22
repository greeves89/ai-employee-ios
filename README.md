# AI-Employee iOS App

Eine native iOS-App für das AI-Employee Backend-System. Die App ermöglicht es Benutzern, ihre KI-Agenten von unterwegs zu verwalten, mit ihnen zu chatten und Aufgaben zu überwachen.

## Funktionen

- **Anmeldung**: Login mit E-Mail und Passwort (gleiche Zugangsdaten wie Web-UI)
- **Agenten-Verwaltung**: Liste aller KI-Agenten, Status anzeigen, Start/Stop/Restart steuern
- **Echtzeit-Chat**: Nachrichten mit Agenten via WebSocket austauschen
- **Sprachsteuerung**: Sprach-zu-Text (SFSpeechRecognizer) für freihändige Eingabe
- **Aufgaben**: Laufende und abgeschlossene Aufgaben und TODOs überwachen
- **Genehmigungen**: Ausstehende Befehle genehmigen oder ablehnen
- **Benachrichtigungen**: In-App Benachrichtigungen in Echtzeit empfangen

## Technologie

- **Framework**: SwiftUI (iOS 17+)
- **Sprache**: Swift 5.9+
- **Netzwerk**: URLSession mit async/await, URLSessionWebSocketTask für WebSocket
- **Spracherkennung**: SFSpeechRecognizer + AVAudioEngine
- **Authentifizierung**: Cookie-basiert (HTTPCookieStorage)
- **Design**: Dunkles Farbschema (Dark Blue Theme)

## Setup

### Voraussetzungen

- Xcode 15+
- iOS 17+ Gerät oder Simulator
- Laufendes AI-Employee Backend

### Konfiguration

1. Repository klonen
2. In Xcode öffnen (Package.swift)
3. App auf Gerät/Simulator bauen und starten
4. Server-URL beim ersten Start eingeben (z.B. `https://ai-employee.example.com`)

### Backend-URL

Die Server-URL wird beim Login eingegeben und in den App-Einstellungen gespeichert. Format:
- HTTPS: `https://ihr-server.com`
- HTTP (nur lokal): `http://192.168.1.100:8000`

## API-Endpunkte

Die App kommuniziert mit folgenden Backend-Endpunkten:

| Methode | Endpunkt | Beschreibung |
|---------|----------|--------------|
| POST | `/api/v1/auth/login` | Anmeldung |
| GET | `/api/v1/agents` | Agenten-Liste |
| POST | `/api/v1/agents/{id}/start` | Agent starten |
| POST | `/api/v1/agents/{id}/stop` | Agent stoppen |
| POST | `/api/v1/agents/{id}/restart` | Agent neu starten |
| POST | `/api/v1/agents/{id}/message` | Nachricht senden |
| GET | `/api/v1/agents/{id}/chat/history` | Chat-Verlauf |
| GET | `/api/v1/tasks` | Aufgaben-Liste |
| GET | `/api/v1/approvals/pending` | Ausstehende Genehmigungen |
| POST | `/api/v1/approvals/{id}/approve` | Genehmigen |
| POST | `/api/v1/approvals/{id}/deny` | Ablehnen |
| GET | `/api/v1/notifications` | Benachrichtigungen |
| POST | `/api/v1/notifications/{id}/read` | Als gelesen markieren |

### WebSocket-Verbindungen

- Chat: `wss://server/api/v1/agents/{id}/chat`
- Benachrichtigungen: `wss://server/api/v1/notifications`

## Projektstruktur

```
Sources/AIEmployee/
├── AIEmployeeApp.swift          # App-Einstiegspunkt
├── Core/
│   ├── APIClient.swift          # REST API Client
│   ├── AuthManager.swift        # Authentifizierungs-Manager
│   ├── WebSocketClient.swift    # WebSocket Client
│   └── VoiceManager.swift       # Spracherkennung
├── Models/
│   ├── Agent.swift              # Agenten-Modell
│   ├── Task.swift               # Aufgaben-Modell
│   ├── ChatMessage.swift        # Chat-Nachrichten-Modell
│   ├── Notification.swift       # Benachrichtigungs-Modell
│   └── Approval.swift           # Genehmigungs-Modell
├── ViewModels/
│   ├── AuthViewModel.swift      # Auth-Logik
│   ├── AgentsViewModel.swift    # Agenten-Logik
│   ├── ChatViewModel.swift      # Chat-Logik
│   ├── TasksViewModel.swift     # Aufgaben-Logik
│   ├── ApprovalsViewModel.swift # Genehmigungs-Logik
│   └── NotificationsViewModel.swift # Benachrichtigungs-Logik
└── Views/
    ├── ContentView.swift        # Root View
    ├── Auth/LoginView.swift     # Login-Ansicht
    ├── Dashboard/               # Dashboard-Ansichten
    ├── Agent/                   # Agenten-Ansichten
    ├── Tasks/                   # Aufgaben-Ansicht
    ├── Approvals/               # Genehmigungs-Ansicht
    └── Notifications/           # Benachrichtigungs-Ansicht
```

## Lizenz

Proprietär - AI-Employee Projekt
