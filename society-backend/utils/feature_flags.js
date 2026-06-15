// Elite Production Feature Flag System
// Allows toggling features without re-deploying

const flags = {
  enableNewMediaFlow: true,
  enableAdvancedDelivery: true,
  enableAutoCleanup: true,
  enableExperimentalV3: false
};

const getFlag = (name) => {
  return flags[name] !== undefined ? flags[name] : false;
};

const setFlag = (name, value) => {
  if (flags[name] !== undefined) {
    flags[name] = value;
    return true;
  }
  return false;
};

const getAllFlags = () => ({ ...flags });

module.exports = {
  getFlag,
  setFlag,
  getAllFlags
};
