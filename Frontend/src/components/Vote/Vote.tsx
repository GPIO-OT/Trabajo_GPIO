// src/components/Vote.tsx
import React, { useState, useEffect } from "react";
import { useParticipants, useFecthVote } from '../../hooks';
import { VoteInfo } from "../../types/Votes";
import { Participant } from "../../types/Participants";
import { ParticipantVoteCard } from "./ParticipantVoteCard";

import "./Vote.css"

const Vote: React.FC = () => {
  const [participants, setParticipants] = useState<
    Participant[]
  >([]);
  const [selectedVote, setSelectedVote] = useState<number | null>(null);
  const [isSelected, setIsSelected] = useState<boolean | null>(null);

  const participantsHook = useParticipants()
  const voteHook = useFecthVote()

  useEffect(() => {
    setParticipants(participantsHook.data);
  }, [participantsHook.data]);

  useEffect(() => {
    if(selectedVote != null){
      setIsSelected(true)
    }
  }, [selectedVote]);

  const handleVote = () => {
    if(selectedVote == null){
      setIsSelected(false)
      return
    }

    // Aquí se enviaría la votación al backend
    const voteInfo : VoteInfo = {participantId : selectedVote}
    voteHook.fecthVote(voteInfo).then((res) => {
        alert("Votación realizada");
      })
      .catch((error) => {
        console.error("Error al votar:", error);
      });
    
  };

  return (
    <div>
      <h2>Votación</h2>
      <div className={"container"}>
        {participants.length === 0 ? (
          <p>Cargando participantes...</p>
        ) : (
          <div className={"grid"} >
          {
            participants.map((participant) => (
              <ParticipantVoteCard 
                participant={participant}
                selectedVote={selectedVote}
                onVote={setSelectedVote}
              />
          ))
          }
          </div>
        )}
        {!isSelected && isSelected !=null ? (
          <div>
            <p>
              Voto no seleccionado
            </p>
          </div>)
          :
          null
        }
        <button className={`main-button`} 
                onClick={handleVote}
        >
          Votar
        </button>
      </div>
    </div>
  );
};

export default Vote;
