// src/components/Login.tsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom'; // Cambiar useHistory por useNavigate

const Login: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate(); // Usar useNavigate

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // En un caso real, aquí iría la validación de las credenciales con el backend.
    localStorage.setItem('loggedIn', 'true'); // Simula un login
    navigate('/vote'); // Redirige a la página de votación
  };

  return (
    <div>
      <h2>Login</h2>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <button type="submit">Login</button>
      </form>
    </div>
  );
};

export default Login;
