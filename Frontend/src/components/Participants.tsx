// src/components/Participants.tsx
import React, { useEffect, useState } from 'react';
import axios from 'axios';

const Participants: React.FC = () => {
  const [participants, setParticipants] = useState<{ id: number, name: string }[]>([]);

  useEffect(() => {
    // Traemos la lista de participantes desde el backend
    axios.get('http://localhost:5000/api/participants')
      .then((response) => {
        setParticipants(response.data);
      });
  }, []);

  return (
    <div>
      <h2>Participantes</h2>
      {participants.length === 0 ? (
        <p>Cargando participantes...</p>
      ) : (
        participants.map((participant) => (
          <div key={participant.id}>
            <p>{participant.name}</p>
          </div>
        ))
      )}
    </div>
  );
};

export default Participants;
