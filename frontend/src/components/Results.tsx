// src/components/Results.tsx
import React, { useEffect, useState } from 'react';
import axios from 'axios';

const Results: React.FC = () => {
  const [results, setResults] = useState<{ participantId: number, votes: number }[]>([]);

  useEffect(() => {
    // Traemos los resultados de la votación desde el backend
    axios.get('http://localhost:5000/api/results')
      .then((response) => {
        setResults(response.data);
      });
  }, []);

  return (
    <div>
      <h2>Resultados de la Votación</h2>
      {results.length === 0 ? (
        <p>Cargando resultados...</p>
      ) : (
        results.map((result) => (
          <div key={result.participantId}>
            <p>Participante {result.participantId}: {result.votes} votos</p>
          </div>
        ))
      )}
    </div>
  );
};

export default Results;
