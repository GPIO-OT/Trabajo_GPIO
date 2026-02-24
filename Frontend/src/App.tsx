// src/App.tsx
import React from "react";
import { BrowserRouter as Router, Routes, Route, Link } from "react-router-dom"; // Asegúrate de importar Link
import Login from "./components/Login/Login";
import Vote from "./components/Vote/Vote";
import Results from "./components/Results/Results";
import Participants from "./components/Participants/Participants";
import { Main } from "./components/Main/Main";

const App: React.FC = () => {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Main element={<Login />} />} />
        <Route path="/vote" element={<Main element={<Vote />} />} />
        <Route path="/results" element={<Main element={<Results />} />} />
        <Route path="/participants" element={<Main element={<Participants />} />} />
        <Route path="*" element={<Login />} />
      </Routes>
    </Router>
  );
};

export default App;
