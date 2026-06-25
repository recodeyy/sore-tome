const { logger } = require("../src/shared/Logger");
const crypto = require("crypto");

class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

function errorHandler(err, req, res, next) {
  const status = err.statusCode || 500;
  const errorId = crypto.randomUUID();
  const requestId = req.requestId || 'unknown';

  // Log the error
  if (status >= 500) {
    logger.error({
      errorId,
      requestId,
      path: req.path,
      method: req.method,
      stack: err.stack,
      userId: req.user?.uid,
    }, "Unhandled System Error");
  } else {
    logger.warn({
      requestId,
      path: req.path,
      method: req.method,
      message: err.message,
      statusCode: status
    }, "API Error");
  }

  res.status(status).json({
    error: err.message || "Internal server error",
    code: err.code || 'INTERNAL_ERROR',
    errorId: status >= 500 ? errorId : undefined,
    requestId: requestId,
  });
}

module.exports = { AppError, errorHandler };
