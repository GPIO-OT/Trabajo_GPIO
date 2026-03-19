import { SideBar } from "../SideBar/SideBar"

import "./Main.css"

interface Props {
  element: React.ReactNode
}

export function Main( {element} : Props) {
  return (
    <>
      <div className={"layout"}>
        <SideBar />
        <main className={"content"}>{element}</main>
      </div>
      
    </>
  )
}