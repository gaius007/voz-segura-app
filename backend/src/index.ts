import express from 'express';
import cors from 'cors';
import * as dotenv from 'dotenv';
import whatsappRouter from './routes/whatsapp';
import { db, initialized } from './config/firebase';
import localtunnel from 'localtunnel';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Configuração geral de CORS para aceitar conexões de emuladores e dispositivos móveis na rede local
app.use(cors());
app.use(express.json());

// Rota padrão de Status/Healthcheck
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'Voz Segura Backend Proxy',
    firebase: initialized ? 'connected' : 'demo_mode',
    timestamp: new Date().toISOString(),
  });
});

// Registro das rotas no prefixo /api/whatsapp
app.use('/api/whatsapp', whatsappRouter);

// Tratamento global de erros para impedir quedas abruptas do servidor
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Express Global Error:', err);
  res.status(500).json({ error: 'Internal Server Error', message: err.message });
});

// Inicializa o servidor Express na porta desejada
app.listen(PORT, async () => {
  console.log(`===================================================`);
  console.log(`🚀 Voz Segura Backend Proxy iniciado com sucesso!`);
  console.log(`📡 Ouvindo na porta: http://localhost:${PORT}`);
  console.log(`🛡️  Firebase Admin: ${initialized ? 'CONECTADO ✅' : 'MODO DEMO ⚠️'}`);
  console.log(`===================================================`);

  // Inicializa o Túnel de Conexão de forma totalmente automática
  try {
    console.log(`🚀 Abrindo túnel localtunnel na porta ${PORT} de forma automática...`);
    const tunnel = await localtunnel({ port: Number(PORT) });

    console.log(`===================================================`);
    console.log(`🔗 Túnel ativo e acessível publicamente em:`);
    console.log(`🌐 ${tunnel.url}`);
    console.log(`===================================================`);

    // Atualiza o documento no Firestore para que o Flutter descubra o IP dinamicamente
    if (initialized && db) {
      try {
        await db.collection('config').doc('backend').set({
          url: tunnel.url,
          updatedAt: new Date().toISOString(),
        });
        console.log(`🎯 Firestore: URL do túnel registrada com sucesso em /config/backend`);
      } catch (err: any) {
        console.error(`❌ Firestore: Falha ao escrever URL do túnel:`, err.message);
      }
    } else {
      console.log(`⚠️  Firestore: Ignorando gravação da URL (Modo DEMO ativo).`);
    }

    tunnel.on('close', () => {
      console.log('🔌 Túnel localtunnel encerrado.');
    });

  } catch (err: any) {
    console.error(`❌ Erro ao abrir túnel localtunnel:`, err.message);
  }
});
