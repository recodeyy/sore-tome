import pino from "pino";
import dotenv from "dotenv";

dotenv.config();

const isDevelopment = process.env.NODE_ENV === "development";

export const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  redact: {
    paths: [
      "password",
      "token",
      "refreshToken",
      "authorization",
      "headers.authorization",
      "phone",
      "email"
    ],
    censor: "[REDACTED]",
  },
  formatters: {

    level: (label) => {
      return { level: label.toUpperCase() };
    },
  },
  transport: isDevelopment
    ? {
        target: "pino-pretty",
        options: {
          colorize: true,
          translateTime: "HH:MM:ss Z",
          ignore: "pid,hostname,env,version",
        },
      }
    : undefined,
  base: {
    env: process.env.NODE_ENV || "production",
    version: "1.1.0",
    service: "society-backend",
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});
