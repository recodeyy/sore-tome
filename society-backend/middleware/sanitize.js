/**
 * Middleware to sanitize user input and prevent XSS
 */
function sanitizeInput(req, res, next) {
  const sanitize = (val) => {
    if (typeof val === 'string') {
      // Basic HTML tag stripping
      return val.replace(/<[^>]*>?/gm, '').trim();
    }
    if (Array.isArray(val)) {
      return val.map(v => sanitize(v));
    }
    if (typeof val === 'object' && val !== null) {
      const sanitizedObj = {};
      for (const key in val) {
        sanitizedObj[key] = sanitize(val[key]);
      }
      return sanitizedObj;
    }
    return val;
  };

  if (req.body) {
    req.body = sanitize(req.body);
  }
  
  if (req.query) {
    req.query = sanitize(req.query);
  }

  next();
}

module.exports = { sanitizeInput };
