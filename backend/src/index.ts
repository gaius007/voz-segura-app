import express from 'express';
import cors from 'cors';
import * as dotenv from 'dotenv';
import * as os from 'os';
import whatsappRouter from './routes/whatsapp';
import { db, initialized } from './config/firebase';
import localtunnel from 'localtunnel';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Configuração geral de CORS para aceitar conexões de emuladores e dispositivos móveis na rede local
app.use(cors());
// Webhooks da Evolution (sync de chats/contatos) podem passar de 100kb — limite maior
app.use(express.json({ limit: '10mb' }));

// IPs internos de container/VM do Docker que não são alcançáveis pelo celular
function isInternalDockerIp(ip: string): boolean {
  if (ip.startsWith('192.168.65.')) return true; // VM do Docker Desktop
  const octets = ip.split('.').map(Number);
  return octets[0] === 172 && octets[1] >= 16 && octets[1] <= 31; // bridges (172.16/12)
}

// Rodando dentro do Docker Desktop o container não enxerga as interfaces do notebook,
// então o IP real da LAN é aprendido pelo header Host das requisições que chegam
// (ex: o app acessa http://192.168.1.114:3000 e esse endereço passa a ser publicado).
const observedHosts = new Set<string>();
app.use((req, res, next) => {
  const host = req.headers.host || '';
  const ip = host.split(':')[0];
  if (/^\d+\.\d+\.\d+\.\d+$/.test(ip) && !ip.startsWith('127.') && !isInternalDockerIp(ip)) {
    if (!observedHosts.has(host) && observedHosts.size < 20) {
      observedHosts.add(host);
      registerBackendUrls();
    }
  }
  next();
});

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

// Coleta os IPs IPv4 da rede local (Wi-Fi, cabo, hotspot) onde o backend está acessível.
// Dentro do Docker Desktop as interfaces visíveis são internas (filtradas) e a descoberta
// real acontece via observedHosts; fora do Docker, enumera as interfaces normalmente.
function getLanUrls(): string[] {
  const urls = new Set<string>();
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    // Ignora bridges/interfaces virtuais do Docker — inalcançáveis pelo celular
    if (/^(docker|br-|veth|virbr)/.test(name)) continue;
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal && !isInternalDockerIp(iface.address)) {
        urls.add(`http://${iface.address}:${PORT}`);
      }
    }
  }
  for (const host of observedHosts) {
    urls.add(`http://${host}`);
  }
  return [...urls];
}

// URL pública do túnel (best-effort, alimentada de forma assíncrona)
let tunnelUrl: string | null = null;
let lastRegistered = '';

// Publica no Firestore os endereços atuais do backend para o app descobrir
// dinamicamente, independente da rede (Wi-Fi A, Wi-Fi B, hotspot...)
async function registerBackendUrls() {
  if (!initialized || !db) return;

  const urls = getLanUrls();
  const snapshot = JSON.stringify({ urls, tunnelUrl });
  if (snapshot === lastRegistered) return; // nada mudou, evita writes desnecessários

  try {
    await db.collection('config').doc('backend').set({
      urls,
      tunnelUrl: tunnelUrl || null,
      // Campo legado mantido por compatibilidade com versões antigas do app
      url: tunnelUrl || urls[0] || null,
      updatedAt: new Date().toISOString(),
    });
    lastRegistered = snapshot;
    console.log(`🎯 Firestore: endereços registrados em /config/backend → ${urls.join(', ')}${tunnelUrl ? ` | túnel: ${tunnelUrl}` : ''}`);
  } catch (err: any) {
    console.error(`❌ Firestore: Falha ao registrar endereços do backend:`, err.message);
  }
}

// Inicializa o servidor Express na porta desejada
app.listen(PORT, async () => {
  console.log(`===================================================`);
  console.log(`🚀 Voz Segura Backend Proxy iniciado com sucesso!`);
  console.log(`📡 Ouvindo na porta: http://localhost:${PORT}`);
  console.log(`🌐 IPs na rede local: ${getLanUrls().join(', ') || 'nenhum detectado'}`);
  console.log(`🛡️  Firebase Admin: ${initialized ? 'CONECTADO ✅' : 'MODO DEMO ⚠️'}`);
  console.log(`===================================================`);

  // Registra os IPs imediatamente e re-verifica a cada 30s (detecta troca de rede)
  await registerBackendUrls();
  setInterval(registerBackendUrls, 30_000);

  // Túnel público como último recurso (quando app e backend estão em redes diferentes).
  // Best-effort e não-bloqueante: a falha do túnel não afeta o uso na rede local.
  try {
    console.log(`🚇 Abrindo túnel localtunnel na porta ${PORT} (best-effort)...`);
    const tunnel = await localtunnel({ port: Number(PORT) });

    tunnelUrl = tunnel.url;
    console.log(`🔗 Túnel ativo: ${tunnel.url}`);
    await registerBackendUrls();

    tunnel.on('close', () => {
      console.log('🔌 Túnel localtunnel encerrado.');
      tunnelUrl = null;
    });
  } catch (err: any) {
    console.error(`⚠️  Túnel localtunnel indisponível (seguindo apenas com rede local):`, err.message);
  }
});
