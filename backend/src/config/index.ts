import dotenv from 'dotenv';

dotenv.config();

interface Config {
  acsConnectionString: string;
  acsPhoneNumber: string;
  port: number;
  nodeEnv: string;
  callbackUri: string;
  frontendUrl: string;
}

const getConfig = (): Config => {
  const required = {
    acsConnectionString: process.env.ACS_CONNECTION_STRING,
    acsPhoneNumber: process.env.ACS_PHONE_NUMBER,
    callbackUri: process.env.CALLBACK_URI,
  };

  // Validate required environment variables
  const missing = Object.entries(required)
    .filter(([_, value]) => !value)
    .map(([key]) => key);

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}\n` +
      'Please check your .env file and ensure all required variables are set.'
    );
  }

  return {
    acsConnectionString: required.acsConnectionString!,
    acsPhoneNumber: required.acsPhoneNumber!,
    port: parseInt(process.env.PORT || '3000', 10),
    nodeEnv: process.env.NODE_ENV || 'development',
    callbackUri: required.callbackUri!,
    frontendUrl: process.env.FRONTEND_URL || 'http://localhost:5173',
  };
};

export const config = getConfig();
