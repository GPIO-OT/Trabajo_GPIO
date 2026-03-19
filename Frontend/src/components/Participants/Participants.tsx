// src/components/Participants.tsx
import React, { useEffect, useState } from 'react';
import { useParticipants } from '../../hooks';
import { Participant } from '../../types/Participants';
import { ParticipantCard } from './ParticipantCard';

const Participants: React.FC = () => {
  const [participants, setParticipants] = useState<Participant[]>([]);

  const participantsHook = useParticipants()
  
  useEffect(() => {
    // Traemos la lista de participantes desde el backend
    setParticipants(participantsHook.data.sort(
      (a, b) => b.votes - a.votes
    ));
  }, [participantsHook.data]);

  return (
    <div>
      <h2>Participantes</h2>
      {participants.length === 0 ? (
        <p>Cargando participantes...</p>
      ) : (
        <div className={"grid"}>
          {
            participants.map((participant: Participant) => {
            
            return <ParticipantCard
              participant={participant}
            />
            })
          }
        </div>
      )}
    </div>
  );
};

export default Participants;
