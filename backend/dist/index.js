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
const whatsapp_1 = __importDefault(require("./routes/whatsapp"));
const firebase_1 = require("./config/firebase");
const localtunnel_1 = __importDefault(require("localtunnel"));
dotenv.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Configuração geral de CORS para aceitar conexões de emuladores e dispositivos móveis na rede local
app.use((0, cors_1.default)());
app.use(express_1.default.json());
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
// Inicializa o servidor Express na porta desejada
app.listen(PORT, async () => {
    console.log(`===================================================`);
    console.log(`🚀 Voz Segura Backend Proxy iniciado com sucesso!`);
    console.log(`📡 Ouvindo na porta: http://localhost:${PORT}`);
    console.log(`🛡️  Firebase Admin: ${firebase_1.initialized ? 'CONECTADO ✅' : 'MODO DEMO ⚠️'}`);
    console.log(`===================================================`);
    // Inicializa o Túnel de Conexão de forma totalmente automática
    try {
        console.log(`🚀 Abrindo túnel localtunnel na porta ${PORT} de forma automática...`);
        const tunnel = await (0, localtunnel_1.default)({ port: Number(PORT) });
        console.log(`===================================================`);
        console.log(`🔗 Túnel ativo e acessível publicamente em:`);
        console.log(`🌐 ${tunnel.url}`);
        console.log(`===================================================`);
        // Atualiza o documento no Firestore para que o Flutter descubra o IP dinamicamente
        if (firebase_1.initialized && firebase_1.db) {
            try {
                await firebase_1.db.collection('config').doc('backend').set({
                    url: tunnel.url,
                    updatedAt: new Date().toISOString(),
                });
                console.log(`🎯 Firestore: URL do túnel registrada com sucesso em /config/backend`);
            }
            catch (err) {
                console.error(`❌ Firestore: Falha ao escrever URL do túnel:`, err.message);
            }
        }
        else {
            console.log(`⚠️  Firestore: Ignorando gravação da URL (Modo DEMO ativo).`);
        }
        tunnel.on('close', () => {
            console.log('🔌 Túnel localtunnel encerrado.');
        });
    }
    catch (err) {
        console.error(`❌ Erro ao abrir túnel localtunnel:`, err.message);
    }
});
