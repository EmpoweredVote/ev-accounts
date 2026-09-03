import winston from 'winston';

const { combine, timestamp, json, colorize, simple } = winston.format;

const isProduction = process.env.NODE_ENV === 'production';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: isProduction
    ? combine(timestamp(), json())
    : combine(colorize(), simple()),
  transports: [new winston.transports.Console()],
});
