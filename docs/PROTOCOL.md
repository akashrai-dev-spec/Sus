# Socket.IO Protocol Specification - Sus

**Namespace**: `/game`  
**Protocol Version**: `1.0.0`

Every client event acknowledges receipt via standard Socket.IO acknowledgment callback returning:
- Success: `{ ok: true, data?: any }`
- Failure: `{ ok: false, code: string, message: string }`

---

## 1. Handshake & Authentication
Clients connect to `/game` with auth payload:
```json
{
  "protocolVersion": "1.0.0",
  "resumeToken": "optional-uuid"
}
```
If `protocolVersion` does not match, connection is rejected with error `ERR_PROTOCOL_MISMATCH`.

---

## 2. Client to Server Events

### `session:hello`
Registers or recovers player profile and session.
- **Payload**:
  ```json
  {
    "name": "Sneaky Otter",
    "color": "#9A0F28",
    "resumeToken": "optional-uuid"
  }
  ```
- **Ack Response Data**:
  ```json
  {
    "playerId": "p-123",
    "resumeToken": "tok-456"
  }
  ```

### `rooms:list`
Requests public rooms overview.
- **Payload**: None
- **Ack Response Data**: Array of open rooms:
  ```json
  [
    {
      "id": "room-abc",
      "name": "Midnight Crew",
      "count": 3,
      "max": 6,
      "locked": true
    }
  ]
  ```

### `rooms:create`
Creates a new PIN-protected room and sets caller as host.
- **Payload**:
  ```json
  {
    "name": "Midnight Crew",
    "pin": "4821",
    "settings": {
      "maxPlayers": 6,
      "imposters": 1,
      "rounds": 2,
      "guessAttempts": 1,
      "category": "Random"
    }
  }
  ```
- **Ack Response Data**: Full room snapshot.

### `rooms:join`
Joins an existing room with 4-digit PIN. Rate limited to 5 wrong PIN attempts per minute per socket.
- **Payload**:
  ```json
  {
    "roomId": "room-abc",
    "pin": "4821"
  }
  ```
- **Ack Response Data**: Full room snapshot.

### `rooms:leave`
Leaves current room. Host migrates to the next player. If room is empty, it is scheduled for deletion.
- **Payload**: None

### `room:updateSettings`
Updates lobby settings (Host only, lobby state only).
- **Payload**: Settings object.

### `game:start`
Initiates the game (Host only, min 3 players).
- **Payload**: None

### `game:ready`
Notifies that the player has viewed their role card.
- **Payload**: None

### `turn:clue`
Submits a clue on player's turn. Max 60 chars. Normal players cannot contain the secret word.
- **Payload**:
  ```json
  {
    "text": "It can be red or green."
  }
  ```

### `accuse:submit`
Initiates an accusation against another alive player.
- **Payload**:
  ```json
  {
    "targetId": "p-789"
  }
  ```

### `imposter:guess`
Imposter attempts to guess the secret word.
- **Payload**:
  ```json
  {
    "word": "Apple"
  }
  ```

### `profile:update`
Updates player name or avatar color.
- **Payload**:
  ```json
  {
    "name": "Quiet Fox",
    "color": "#1D4ED8"
  }
  ```

---

## 3. Server to Client Broadcasts & Unicast Events

### `room:state` (Broadcast to room)
Full public snapshot sent on state mutations.
```json
{
  "id": "room-abc",
  "name": "Midnight Crew",
  "pin": "4821",
  "max": 6,
  "hostId": "p-123",
  "players": [
    { "id": "p-123", "name": "Sneaky Otter", "color": "#9A0F28", "isHost": true, "isAlive": true }
  ],
  "settings": {
    "imposters": 1,
    "rounds": 2,
    "guessAttempts": 1,
    "category": "Objects & Food"
  },
  "phase": "discussion",
  "currentTurn": {
    "speakerId": "p-123",
    "round": 1,
    "turnIndex": 0
  },
  "clues": [
    { "playerId": "p-123", "text": "It's round and sweet." }
  ],
  "usedAccusations": [],
  "isFinalVote": false
}
```

### `game:role` (Strictly Unicast to Individual Socket)
- **Normal Player**:
  ```json
  {
    "role": "normal",
    "word": "Apple",
    "category": "Objects & Food"
  }
  ```
- **Imposter**:
  ```json
  {
    "role": "imposter",
    "category": "Objects & Food"
  }
  ```

### `game:turn` (Broadcast)
Notifies turn change and active speaker.

### `game:clue` (Broadcast)
Emitted whenever a new valid clue is accepted.

### `game:accusation` (Broadcast)
Announces accusation results:
```json
{
  "accuserId": "p-123",
  "targetId": "p-456",
  "revealedRole": "imposter",
  "outcome": "caught"
}
```

### `game:ended` (Broadcast)
```json
{
  "winner": "normal",
  "reason": "Every imposter was caught.",
  "secretWord": "Apple",
  "category": "Objects & Food",
  "allRoles": {
    "p-123": "normal",
    "p-456": "imposter"
  }
}
```

### `room:playerJoined`, `room:playerLeft`, `room:playerDisconnected`, `room:playerReconnected`
Life-cycle events for room participant updates.
