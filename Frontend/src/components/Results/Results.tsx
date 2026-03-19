// src/components/Results.tsx
import React, { useEffect, useState } from 'react';
import { useParticipants } from '../../hooks';
import { ParticipantChart } from './ParticipantChart';
import { Participant } from '../../types/Participants';

const Results: React.FC = () => {
  const [results, setResults] = useState<Participant[]>([]);

  const voteResultsHook = useParticipants()

  useEffect(() => {
    // Traemos los resultados de la votación desde el backend
    setResults(voteResultsHook.data.sort(
      (a, b) => b.votes - a.votes
    )); 
  }, [voteResultsHook.data]);

  return (
    <div>
      <h2>Resultados de la Votación</h2>
      <ParticipantChart participants={results} />
    </div>
  );
};

export default Results;
