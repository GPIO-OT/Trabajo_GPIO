import { Participant } from "../../types/Participants"
import "./ParticipantCard.css"

interface Props {
  participant: Participant
}

export const ParticipantCard = ({ participant }: Props) => {
  return (
    <div className="card">
      <h2>{participant.name}</h2>
      <p className="votes">{participant.votes} votos</p>
    </div>
  )
}