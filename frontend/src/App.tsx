// src/App.tsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom'; // Asegúrate de importar Link
import Login from './components/Login';
import Vote from './components/Vote';
import Results from './components/Results';
import Participants from './components/Participants';

const App: React.FC = () => {
  return (
    <Router>
      <div>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/vote" element={<Vote />} />
          <Route path="/results" element={<Results />} />
          <Route path="/participants" element={<Participants />} />
          <Route path="/" element={<h1>Bienvenido al Sistema de Votación <Link to="/login">Iniciar sesión</Link></h1>} />
        </Routes>
      </div>
    </Router>
  );
};

export default App;
