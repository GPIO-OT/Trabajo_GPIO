import { useNavigate } from "react-router-dom"
import { SideBarMenuItem } from "../../types/SideBar"

import "./SideBar.css"

const menuItems: SideBarMenuItem[] = [
  { id: "vote", label: "Votar" },
  { id: "participants", label: "Participantes" },
  { id: "results", label: "Resultados" }
]

export const SideBar = () => {

  const navigate = useNavigate();
  const goToView = (item: SideBarMenuItem)=>{

    navigate(`/${item.id}`);
  }



  return (
    <aside className="sidebar">
      <h2 className="logo">Voto-App</h2>

      <nav>
        {menuItems.map(item => (
          <div
            key={item.id}
            id={item.id}
            className={`menu-item`}
            onClick={()=>{goToView(item)}}
          >
            {item.label}
          </div>
        ))}
      </nav>
    </aside>
  )
}