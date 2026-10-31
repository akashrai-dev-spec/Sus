import dotenv from "dotenv";

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || "3000", 10),
  nodeEnv: process.env.NODE_ENV || "development",
  protocolVersion: "1.0.0",
  corsOrigin: process.env.CORS_ORIGIN || "*",
  logLevel: process.env.LOG_LEVEL || "info",
  disconnectGracePeriodMs: parseInt(process.env.DISCONNECT_GRACE_PERIOD_MS || "60000", 10),
  emptyRoomRetentionMs: parseInt(process.env.EMPTY_ROOM_RETENTION_MS || "120000", 10),
};
