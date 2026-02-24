import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  ResponsiveContainer
} from "recharts"
import { Participant } from "../../types/Participants"

interface Props {
  participants: Participant[]
}

export const ParticipantChart = ({ participants }: Props) => {
  return (
    <div>
        <div style={{ width: "100%", height: 500 }}>
        <ResponsiveContainer>
            <BarChart data={participants}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Bar 
                dataKey="votes"
                fill="#2563eb"
                />
            </BarChart>
        </ResponsiveContainer>
        </div>
    </div>
  )
}