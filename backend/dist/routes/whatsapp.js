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
const express_1 = require("express");
const axios_1 = __importDefault(require("axios"));
const auth_1 = require("../middleware/auth");
const firebase_1 = require("../config/firebase");
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const router = (0, express_1.Router)();
const EVOLUTION_API_URL = process.env.EVOLUTION_API_URL || 'http://localhost:8080';
const EVOLUTION_API_KEY = process.env.EVOLUTION_API_KEY || 'sua_super_global_api_key_aqui';
// Helper para verificar se a Evolution API está configurada com credenciais reais
const isEvolutionConfigured = () => {
    return process.env.EVOLUTION_API_URL !== undefined && process.env.EVOLUTION_API_KEY !== undefined;
};
// Imagem PNG mockada de 50x50px em Base64 para emular um QR Code caso esteja em modo offline/desenvolvimento
const MOCK_QR_CODE_BASE64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH6AYbERQLDRt2JAAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLm4clQAAAJBJREFUaN7tmkEKwCAMBMe+/6fbQy+lhBKiux4EpYexm01mre257V3W2t4b/2oYcMQxV+Nq3C0a17g7jrnjsMa22KtxNq7G2bhbNK5x7+5w6fC5w6XD7+9wdziOueOwNuNo3C0a17h3d7h0+NzhcsOAI465GlfjbtG4xt1xzB2HNbYad2rcN36C1LgT8D22CjF3EAAAAABJRU5ErkJggg==';
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
// Configura o webhook da instância apontando de volta para este proxy.
// byEvents DEVE ser false: com true a Evolution posta em subpaths (/connection-update)
// que este router não atende — os eventos se perderiam em 404.
async function configureInstanceWebhook(instanceName) {
    const webhookBase = process.env.WEBHOOK_BASE_URL || `http://host.docker.internal:${process.env.PORT || 3000}`;
    const webhookUrl = `${webhookBase}/api/whatsapp/webhook`;
    await axios_1.default.post(`${EVOLUTION_API_URL}/webhook/set/${instanceName}`, {
        webhook: {
            enabled: true,
            url: webhookUrl,
            byEvents: false,
            events: ['CONNECTION_UPDATE', 'QRCODE_UPDATED'],
        },
    }, {
        headers: { apikey: EVOLUTION_API_KEY },
        timeout: 4000,
    });
    console.log(`EvolutionProxy: Webhook configurado com sucesso para ${webhookUrl}`);
}
// 1. GET /connect - Cria instância e obtém o QR Code para pareamento
router.get('/connect', auth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return res.status(400).json({ error: 'User UID not found in session.' });
    const instanceName = `user_${uid}`;
    console.log(`EvolutionProxy: Solicitando conexão para a instância ${instanceName}`);
    // Se não estiver configurado, rodamos em modo DEMO/MOCK
    if (!isEvolutionConfigured()) {
        console.log(`EvolutionProxy: ⚠️ Evolution API não configurada. Retornando QR Code Mock.`);
        // Simula um delay de carregamento
        await new Promise((resolve) => setTimeout(resolve, 800));
        return res.json({ qrcode: MOCK_QR_CODE_BASE64 });
    }
    try {
        // Passo A: Tenta criar a instância (caso não exista)
        // integration: 'WHATSAPP-BAILEYS' é obrigatório na Evolution API v2
        try {
            await axios_1.default.post(`${EVOLUTION_API_URL}/instance/create`, {
                instanceName: instanceName,
                integration: 'WHATSAPP-BAILEYS',
                qrcode: true,
                token: instanceName,
            }, {
                headers: { apikey: EVOLUTION_API_KEY },
                timeout: 5000,
            });
            console.log(`EvolutionProxy: Instância ${instanceName} criada com sucesso.`);
        }
        catch (err) {
            console.log(`EvolutionProxy: Instância ${instanceName} já existe ou falhou na criação: ${err.message}`);
        }
        // Passo B: Configura o Webhook da instância para apontar de volta para o nosso Proxy
        // Usa host.docker.internal (fixo) para que o container Evolution API sempre alcance o backend no host
        try {
            await configureInstanceWebhook(instanceName);
        }
        catch (err) {
            console.warn(`EvolutionProxy: Falha ao configurar webhook da instância: ${err.message}`);
        }
        // Passo C: Solicita o QR Code de conexão
        const response = await axios_1.default.get(`${EVOLUTION_API_URL}/instance/connect/${instanceName}`, {
            headers: { apikey: EVOLUTION_API_KEY },
            timeout: 8000,
        });
        // Somente os campos `base64` contêm a imagem do QR Code;
        // `code` é a string raw do QR (formato "2@...") e não pode ser tratada como imagem
        let qrcodeBase64 = '';
        if (response.data) {
            qrcodeBase64 = response.data.base64 || response.data.qrcode?.base64 || '';
        }
        if (!qrcodeBase64) {
            throw new Error('Nenhum QR Code no payload de retorno da Evolution API.');
        }
        // Garante prefixo correto data:image/png;base64,
        if (!qrcodeBase64.startsWith('data:')) {
            qrcodeBase64 = `data:image/png;base64,${qrcodeBase64}`;
        }
        return res.json({ qrcode: qrcodeBase64 });
    }
    catch (error) {
        console.error(`EvolutionProxy: ❌ Falha ao obter QR Code da Evolution API: ${error.message}`);
        return res.status(502).json({ error: `Falha ao obter QR Code: ${error.message}` });
    }
});
// 2. POST /disconnect - Deleta a instância na Evolution API e reseta status no Firestore
router.post('/disconnect', auth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return res.status(400).json({ error: 'User UID not found.' });
    const instanceName = `user_${uid}`;
    console.log(`EvolutionProxy: Desconectando e deletando a instância ${instanceName}`);
    // Atualiza Firestore localmente
    if (firebase_1.initialized && firebase_1.db) {
        try {
            await firebase_1.db.collection('users').doc(uid).update({
                whatsappConnected: false,
            });
            console.log(`EvolutionProxy: Status atualizado para DESCONECTADO no Firestore do usuário ${uid}`);
        }
        catch (err) {
            console.error(`EvolutionProxy: Falha ao atualizar Firestore:`, err.message);
        }
    }
    // Se não estiver configurado, mockamos a exclusão com sucesso
    if (!isEvolutionConfigured()) {
        return res.json({ success: true, message: 'Dispositivo desconectado (modo DEMO).' });
    }
    try {
        // Solicita exclusão física da instância para liberar recursos
        await axios_1.default.delete(`${EVOLUTION_API_URL}/instance/delete/${instanceName}`, {
            headers: { apikey: EVOLUTION_API_KEY },
            timeout: 5000,
        });
        return res.json({ success: true });
    }
    catch (error) {
        console.error(`EvolutionProxy: ❌ Erro ao deletar instância na Evolution API:`, error.message);
        // Mesmo se falhar na API externa, retornamos sucesso porque limpamos o status no Firestore
        return res.json({ success: true, warning: 'Instância já estava deletada ou limpa.' });
    }
});
// 3. POST /send - Dispara mensagem automática de SOS usando a instância do usuário emissor
router.post('/send', auth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    const { recipient, message } = req.body;
    if (!uid)
        return res.status(400).json({ error: 'User UID not found.' });
    if (!recipient || !message) {
        return res.status(400).json({ error: 'Parameters "recipient" and "message" are required.' });
    }
    const instanceName = `user_${uid}`;
    console.log(`EvolutionProxy: Disparando SOS silencioso de ${instanceName} para ${recipient}`);
    // Se estiver em modo offline/desenvolvimento
    if (!isEvolutionConfigured()) {
        console.log(`EvolutionProxy: ⚠️ Modo DEMO. Disparo de WhatsApp silencioso simulado com sucesso.`);
        console.log(`[MOCK WHATSAPP] De: ${instanceName} -> Para: ${recipient} | Mensagem: ${message}`);
        return res.status(200).json({ success: true, mockMode: true });
    }
    try {
        // Formata o número limpando caracteres especiais
        let cleanNumber = recipient.replace(/\D/g, '');
        // Payload achatado da Evolution API v2 (o formato v1 com options/textMessage retorna 400)
        const response = await axios_1.default.post(`${EVOLUTION_API_URL}/message/sendText/${instanceName}`, {
            number: cleanNumber,
            text: message,
            delay: 1200,
        }, {
            headers: { apikey: EVOLUTION_API_KEY },
            timeout: 8000,
        });
        console.log(`EvolutionProxy: ✅ SOS disparado com sucesso via Evolution API!`);
        return res.status(200).json({ success: true, data: response.data });
    }
    catch (error) {
        // Falha REAL deve chegar ao app para ativar os fallbacks (wa.me / SMS).
        // Nunca simular sucesso aqui: em um SOS a mensagem simplesmente não seria enviada.
        const detail = error.response?.data ? JSON.stringify(error.response.data) : error.message;
        console.error(`EvolutionProxy: ❌ Falha no disparo silencioso: ${detail}`);
        return res.status(502).json({ success: false, error: `Falha no envio via Evolution API: ${detail}` });
    }
});
// 4. GET /pairing-code - Gera e retorna o código de 8 caracteres para vinculação fácil
// Na Evolution API v2.3.x o pairingCode é gerado ASSINCRONAMENTE pelo Baileys (~1s após o
// primeiro QR), então a resposta do POST /instance/create é apenas um fast path; o caminho
// confiável é GET /instance/connect/{instance}?number=NNN com retry até o código aparecer.
router.get('/pairing-code', auth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return res.status(400).json({ error: 'User UID not found in session.' });
    const instanceName = `user_${uid}`;
    if (!isEvolutionConfigured()) {
        console.log(`EvolutionProxy: ⚠️ Evolution API não configurada. Gerando pairing code de teste.`);
        const segments = [
            Math.random().toString(36).substring(2, 6).toUpperCase(),
            Math.random().toString(36).substring(2, 6).toUpperCase(),
        ];
        return res.json({ code: segments.join('-') });
    }
    try {
        // Obtém o número de telefone do Firestore (garante conversão para string)
        let phoneNumber = '';
        if (firebase_1.initialized && firebase_1.db) {
            const userDoc = await firebase_1.db.collection('users').doc(uid).get();
            if (userDoc.exists) {
                phoneNumber = String(userDoc.data()?.phoneNumber || '');
            }
        }
        if (!phoneNumber) {
            return res.status(400).json({ error: 'Número de telefone do usuário não encontrado para pareamento.' });
        }
        // Limpa para somente dígitos (E.164 sem o +)
        let cleanNumber = phoneNumber.replace(/\D/g, '');
        // Trata 9º dígito brasileiro se solicitado
        const removeNinthDigit = req.query.removeNinthDigit === 'true';
        if (removeNinthDigit && cleanNumber.startsWith('55') && cleanNumber.length === 13 && cleanNumber[4] === '9') {
            cleanNumber = cleanNumber.slice(0, 4) + cleanNumber.slice(5);
            console.log(`EvolutionProxy: 9º dígito removido → ${cleanNumber}`);
        }
        // Deleta instância anterior para garantir estado limpo e novo pairingCode
        // (sessão em "close" com 401 não se recupera sozinha)
        try {
            await axios_1.default.delete(`${EVOLUTION_API_URL}/instance/delete/${instanceName}`, {
                headers: { apikey: EVOLUTION_API_KEY },
                timeout: 5000,
            });
            console.log(`EvolutionProxy: Instância anterior deletada.`);
            await sleep(500);
        }
        catch (e) { }
        console.log(`EvolutionProxy: Criando instância ${instanceName} com número ${cleanNumber} para gerar pairingCode`);
        const createResponse = await axios_1.default.post(`${EVOLUTION_API_URL}/instance/create`, {
            instanceName,
            integration: 'WHATSAPP-BAILEYS',
            number: cleanNumber,
            qrcode: true,
            token: instanceName,
        }, {
            headers: { apikey: EVOLUTION_API_KEY },
            timeout: 10000,
        });
        // Configura webhook para receber eventos de conexão
        try {
            await configureInstanceWebhook(instanceName);
        }
        catch (e) {
            console.warn(`EvolutionProxy: Webhook config falhou: ${e.message}`);
        }
        // Fast path: às vezes o create já responde com o pairingCode
        let code = createResponse.data?.qrcode?.pairingCode || '';
        // Caminho principal: pede o código via /instance/connect com retry, já que o
        // Baileys só o gera ~1s depois do handshake inicial
        for (let attempt = 1; !code && attempt <= 5; attempt++) {
            await sleep(2000);
            try {
                const connectResponse = await axios_1.default.get(`${EVOLUTION_API_URL}/instance/connect/${instanceName}?number=${cleanNumber}`, { headers: { apikey: EVOLUTION_API_KEY }, timeout: 8000 });
                code = connectResponse.data?.pairingCode || connectResponse.data?.qrcode?.pairingCode || '';
                console.log(`EvolutionProxy: Tentativa ${attempt}/5 de obter pairingCode → ${code || 'ainda não disponível'}`);
            }
            catch (e) {
                console.warn(`EvolutionProxy: Tentativa ${attempt}/5 falhou: ${e.message}`);
            }
        }
        if (!code) {
            throw new Error('Pairing code não foi gerado pela Evolution API. Verifique se o número está correto (com DDI 55 e 9º dígito).');
        }
        console.log(`EvolutionProxy: ✅ Pairing Code gerado: ${code} para número ${cleanNumber}`);
        return res.json({ code });
    }
    catch (error) {
        console.error(`EvolutionProxy: ❌ Falha ao gerar Pairing Code: ${error.message}`);
        return res.status(500).json({ error: `Falha ao gerar pairing code: ${error.message}` });
    }
});
// 5. GET /status - Verifica e sincroniza o estado de conexão manualmente (fallback para webhook)
router.get('/status', auth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return res.status(400).json({ error: 'User UID not found.' });
    const instanceName = `user_${uid}`;
    if (!isEvolutionConfigured()) {
        return res.json({ connected: false, state: 'demo_mode' });
    }
    try {
        const response = await axios_1.default.get(`${EVOLUTION_API_URL}/instance/connectionState/${instanceName}`, { headers: { apikey: EVOLUTION_API_KEY }, timeout: 5000 });
        const state = response.data?.instance?.state || response.data?.state || 'unknown';
        const isConnected = state === 'open';
        if (isConnected && firebase_1.initialized && firebase_1.db) {
            // Firestore update é best-effort — falha não deve bloquear a resposta
            firebase_1.db.collection('users').doc(uid).update({ whatsappConnected: true })
                .then(() => console.log(`EvolutionProxy: ✅ Firestore atualizado — ${instanceName} CONECTADO`))
                .catch((err) => console.warn(`EvolutionProxy: ⚠️ Firestore update falhou: ${err.message}`));
        }
        return res.json({ connected: isConnected, state });
    }
    catch (error) {
        console.warn(`EvolutionProxy: ⚠️ Falha ao verificar status (${error.message})`);
        return res.json({ connected: false, state: 'error', error: error.message });
    }
});
// Aceita também subpaths (/webhook/connection-update) caso alguma instância
// antiga ainda esteja configurada com byEvents=true
router.post(['/webhook', '/webhook/:event'], async (req, res) => {
    const { event, instance, data } = req.body;
    if (!event || !instance) {
        return res.status(200).json({ status: 'ignored', reason: 'No event or instance information' });
    }
    console.log(`EvolutionWebhook: Evento "${event}" recebido para instância "${instance}"`);
    // Filtra apenas o evento de alteração de conexão
    if (event === 'connection.update' || event === 'CONNECTION_UPDATE') {
        const userId = instance.replace('user_', '');
        const status = data?.status || data?.state;
        const isConnected = status === 'open' || status === 'CONNECTED';
        console.log(`EvolutionWebhook: Instância ${instance} atualizou status para ${status} (Connected: ${isConnected})`);
        if (firebase_1.initialized && firebase_1.db) {
            try {
                await firebase_1.db.collection('users').doc(userId).update({
                    whatsappConnected: isConnected,
                });
                console.log(`EvolutionWebhook: ✅ Firestore atualizado reativamente para o usuário ${userId}`);
            }
            catch (err) {
                console.error(`EvolutionWebhook: ❌ Falha ao atualizar Firestore do usuário:`, err.message);
            }
        }
        else {
            console.warn('EvolutionWebhook: ⚠️ Firestore indisponível para atualização reativa.');
        }
    }
    return res.status(200).json({ status: 'processed' });
});
exports.default = router;
