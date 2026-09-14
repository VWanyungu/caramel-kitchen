import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import { AuthProvider } from './auth/AuthContext.tsx'
import { PremiumModalProvider } from './context/PremiumModalContext.tsx'
import { NavigationProvider } from './context/NavigationContext.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <PremiumModalProvider>
          <NavigationProvider>
            <App />
          </NavigationProvider>
        </PremiumModalProvider>
      </AuthProvider>
    </BrowserRouter>
  </StrictMode>,
)
