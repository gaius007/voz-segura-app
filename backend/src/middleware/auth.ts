import { Request, Response, NextFunction } from 'express';
import { auth, initialized } from '../config/firebase';

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    [key: string]: any;
  };
}

export async function requireAuth(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized. No Bearer token provided in Authorization header.' });
  }

  const token = authHeader.split(' ')[1];

  // Fallback para desenvolvimento local caso o Firebase não tenha sido inicializado com credenciais administrativas
  if (!initialized || !auth) {
    console.log('FirebaseAuth Middleware: ⚠️ Backend em modo de DEMO. Autenticação mockada a partir do token...');
    // Se o token começar com demo_ extrai o resto como uid, senão usa um fixo
    const uid = token.startsWith('demo_') ? token : 'demo_user_uid_123';
    req.user = { uid, email: 'demo@vozsegura.org' };
    return next();
  }

  try {
    const decodedToken = await auth.verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };
    next();
  } catch (error: any) {
    console.error('FirebaseAuth Middleware: ❌ Falha ao verificar Token JWT:', error.message);
    return res.status(401).json({ error: 'Unauthorized. Token inválido ou expirado.', details: error.message });
  }
}
