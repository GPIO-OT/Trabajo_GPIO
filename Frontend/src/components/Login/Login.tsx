// src/components/Login.tsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFecthLogin } from '../../hooks';
import { AuthResponse, LoginRequest } from '../../types/Auth';

import "./Login.css"

const Login: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const loginHook = useFecthLogin()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const loginRequest : LoginRequest ={ user: username, password: password }
      const authResponse : AuthResponse | null = await loginHook.fecthLogin( loginRequest)
      if(authResponse != null){
        navigate('/vote');
      }else{
        setError('Usuario o contraseña incorrectos');
      }
    } catch {
      setError('Usuario o contraseña incorrectos');
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
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
        {error && <p className="error">{error}</p>}
      </div>
    </div>
  );
};

export default Login;
