export interface CallRequest {
  targetPhoneNumber: string;
  sourceCallerId?: string;
}

export interface CallResponse {
  callConnectionId: string;
  status: string;
  message?: string;
}

export interface CallState {
  isActive: boolean;
  callConnectionId: string | null;
  phoneNumber: string;
  status: 'idle' | 'calling' | 'connected' | 'disconnected' | 'error';
  startTime?: Date;
  error?: string;
}
