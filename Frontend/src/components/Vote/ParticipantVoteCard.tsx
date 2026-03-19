import { Participant } from "../../types/Participants"
import "./ParticipantVoteCard.css"

interface Props {
  participant: Participant,
  selectedVote:number | null,
  onVote:  (id: number) => void
}

export const ParticipantVoteCard = ({ participant, selectedVote, onVote}: Props) => {

  const isSelected = selectedVote === participant.id

  return (
    <div className={`card ${isSelected ? "selected" : ""}`}>
      <h2>{participant.name}</h2>
      <button
        disabled={isSelected}
        className={isSelected ? "btn-disabled" : ""}
        onClick={() => onVote(participant.id)}
        >
          {isSelected ? "Votado" : "Votar"}
      </button>
    </div>
  )
}