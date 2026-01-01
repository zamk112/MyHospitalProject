import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
import fs from 'node:fs';


const certName = 'hospitalproject.client';
const certFolder = path.join(`${process.env.LOCALAPPDATA}`, 'ASP.NET', 'https');
const certPath = path.join(certFolder, `${certName}.pem`);
const keyPath = path.join(certFolder, `${certName}.key`);

if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
  throw new Error('Certificate not found.');
}

const target = 'https://localhost:7276';

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [['babel-plugin-react-compiler']],
      },
    }),
  ],
  server: {
    port: 5173,
    https: {
      key: fs.readFileSync(keyPath),
      cert: fs.readFileSync(certPath),
    },
    proxy: {
      '^/weatherforecast': {
        target: target,
        secure: true,
      },      
    },
  },
})
