import { Router } from 'express';
import { webhookController } from '../controllers/webhookController';

const router = Router();

// Webhook endpoints for Azure Communication Services
router.post('/events', (req, res) => webhookController.handleCallEvents(req, res));

export default router;
