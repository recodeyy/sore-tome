export const getDocument = () => ({
  promise: Promise.resolve({
    numPages: 0,
    getPage: () => ({
      getTextContent: () => Promise.resolve({ items: [] }),
      getViewport: () => ({ width: 100, height: 100 }),
      render: () => ({ promise: Promise.resolve() }),
    }),
  }),
});
