"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv = __importStar(require("dotenv"));
const os = __importStar(require("os"));
const whatsapp_1 = __importDefault(require("./routes/whatsapp"));
const firebase_1 = require("./config/firebase");
const localtunnel_1 = __importDefault(require("localtunnel"));
dotenv.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Configuração geral de CORS para aceitar conexões de emuladores e dispositivos móveis na rede local
app.use((0, cors_1.default)());
// Webhooks da Evolution (sync de chats/contatos) podem passar de 100kb — limite maior
app.use(express_1.default.json({ limit: '10mb' }));
// IPs internos de container/VM do Docker que não são alcançáveis pelo celular
function isInternalDockerIp(ip) {
    if (ip.startsWith('192.168.65.'))
        return true; // VM do Docker Desktop
    const octets = ip.split('.').map(Number);
    return octets[0] === 172 && octets[1] >= 16 && octets[1] <= 31; // bridges (172.16/12)
}
// Rodando dentro do Docker Desktop o container não enxerga as interfaces do notebook,
// então o IP real da LAN é aprendido pelo header Host das requisições que chegam
// (ex: o app acessa http://192.168.1.114:3000 e esse endereço passa a ser publicado).
const observedHosts = new Set();
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
        firebase: firebase_1.initialized ? 'connected' : 'demo_mode',
        timestamp: new Date().toISOString(),
    });
});
// Registro das rotas no prefixo /api/whatsapp
app.use('/api/whatsapp', whatsapp_1.default);
// Tratamento global de erros para impedir quedas abruptas do servidor
app.use((err, req, res, next) => {
    console.error('Express Global Error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
});
// Coleta os IPs IPv4 da rede local (Wi-Fi, cabo, hotspot) onde o backend está acessível.
// Dentro do Docker Desktop as interfaces visíveis são internas (filtradas) e a descoberta
// real acontece via observedHosts; fora do Docker, enumera as interfaces normalmente.
function getLanUrls() {
    const urls = new Set();
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        // Ignora bridges/interfaces virtuais do Docker — inalcançáveis pelo celular
        if (/^(docker|br-|veth|virbr)/.test(name))
            continue;
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
let tunnelUrl = null;
let lastRegistered = '';
// Publica no Firestore os endereços atuais do backend para o app descobrir
// dinamicamente, independente da rede (Wi-Fi A, Wi-Fi B, hotspot...)
async function registerBackendUrls() {
    if (!firebase_1.initialized || !firebase_1.db)
        return;
    const urls = getLanUrls();
    const snapshot = JSON.stringify({ urls, tunnelUrl });
    if (snapshot === lastRegistered)
        return; // nada mudou, evita writes desnecessários
    try {
        await firebase_1.db.collection('config').doc('backend').set({
            urls,
            tunnelUrl: tunnelUrl || null,
            // Campo legado mantido por compatibilidade com versões antigas do app
            url: tunnelUrl || urls[0] || null,
            updatedAt: new Date().toISOString(),
        });
        lastRegistered = snapshot;
        console.log(`🎯 Firestore: endereços registrados em /config/backend → ${urls.join(', ')}${tunnelUrl ? ` | túnel: ${tunnelUrl}` : ''}`);
    }
    catch (err) {
        console.error(`❌ Firestore: Falha ao registrar endereços do backend:`, err.message);
    }
}
// Inicializa o servidor Express na porta desejada
app.listen(PORT, async () => {
    console.log(`===================================================`);
    console.log(`🚀 Voz Segura Backend Proxy iniciado com sucesso!`);
    console.log(`📡 Ouvindo na porta: http://localhost:${PORT}`);
    console.log(`🌐 IPs na rede local: ${getLanUrls().join(', ') || 'nenhum detectado'}`);
    console.log(`🛡️  Firebase Admin: ${firebase_1.initialized ? 'CONECTADO ✅' : 'MODO DEMO ⚠️'}`);
    console.log(`===================================================`);
    // Registra os IPs imediatamente e re-verifica a cada 30s (detecta troca de rede)
    await registerBackendUrls();
    setInterval(registerBackendUrls, 30_000);
    // Túnel público como último recurso (quando app e backend estão em redes diferentes).
    // Best-effort e não-bloqueante: a falha do túnel não afeta o uso na rede local.
    try {
        console.log(`🚇 Abrindo túnel localtunnel na porta ${PORT} (best-effort)...`);
        const tunnel = await (0, localtunnel_1.default)({ port: Number(PORT) });
        tunnelUrl = tunnel.url;
        console.log(`🔗 Túnel ativo: ${tunnel.url}`);
        await registerBackendUrls();
        tunnel.on('close', () => {
            console.log('🔌 Túnel localtunnel encerrado.');
            tunnelUrl = null;
        });
    }
    catch (err) {
        console.error(`⚠️  Túnel localtunnel indisponível (seguindo apenas com rede local):`, err.message);
    }
});
