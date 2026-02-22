// src/components/Vote.tsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Vote: React.FC = () => {
  const [participants, setParticipants] = useState<{ id: number, name: string }[]>([]);
  const [selectedVote, setSelectedVote] = useState<number | null>(null);

  useEffect(() => {
    // Aquí traemos los participantes desde el backend
    axios.get('http://localhost:5000/api/participants') // Asegúrate de que el backend esté corriendo
      .then((response) => {
        setParticipants(response.data);
      });
  }, []);

  const handleVote = () => {
    if (selectedVote !== null) {
      // Aquí se enviaría la votación al backend
      axios.post('http://localhost:5000/api/vote', { participantId: selectedVote })
        .then(() => {
          alert('Votación realizada');
        })
        .catch((error) => {
          console.error('Error al votar:', error);
        });
    }
  };

  return (
    <div>
      <h2>Votación</h2>
      {participants.length === 0 ? (
        <p>Cargando participantes...</p>
      ) : (
        participants.map((participant) => (
          <div key={participant.id}>
            <input
              type="radio"
              name="vote"
              value={participant.id}
              onChange={() => setSelectedVote(participant.id)}
            />
            <label>{participant.name}</label>
          </div>
        ))
      )}
      <button onClick={handleVote} disabled={selectedVote === null}>
        Votar
      </button>
    </div>
  );
};

export default Vote;
